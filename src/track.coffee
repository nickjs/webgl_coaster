class LW.Track extends THREE.Object3D
  railRadius: 1
  railDistance: 2
  railRadialSegments: 8
  numberOfRails: 2

  spineShape: null
  spineDivisionLength: 5
  spineShapeNeedsUpdate: true

  tieShape: null
  tieDepth: 1
  tieShapeNeedsUpdate: true

  debugNormals: false

  constructor: (@spline, options) ->
    super()

    for key, value of options
      @[key] = value

  UP = new THREE.Vector3(0, 1, 0)
  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

  rebuild: ->
    @clear()

    @prepareRails()
    @prepareTies()
    @prepareSpine()

    totalLength = Math.ceil(@spline.getLength())
    spineSteps = 0

    binormal = new THREE.Vector3
    normal = new THREE.Vector3

    for i in [0..totalLength]
      u = i / totalLength

      curve = @spline.getCurveAt(u)
      pos = @spline.getPointAt(u)
      tangent = @spline.getTangentAt(u).normalize()

      bank = THREE.Math.degToRad(@spline.getBankAt(u))
      binormal.copy(UP).applyAxisAngle(tangent, bank)

      normal.crossVectors(tangent, binormal).normalize()
      binormal.crossVectors(normal, tangent).normalize()

      if !lastSpinePos or lastSpinePos.distanceTo(pos) >= @spineDivisionLength
        @tieStep(pos, normal, binormal, curve != lastSpineCurve)
        @spineStep(pos, normal, binormal)

        spineSteps++
        lastSpinePos = pos
        lastSpineCurve = curve

      @railStep(pos, normal, binormal)

      if @debugNormals
        @add(new THREE.ArrowHelper(normal, pos, 5, 0x00ff00))
        @add(new THREE.ArrowHelper(binormal, pos, 5, 0x0000ff))

    @spineStep(pos, normal, binormal)

    @finalizeRails(totalLength)
    @finalizeTies(spineSteps)
    @finalizeSpine(spineSteps)

  ###
  # Rail Drawing
  ###

  prepareRails: ->
    @railGeometry = new THREE.Geometry
    @_railGrids = []
    for i in [0..@numberOfRails - 1]
      @_railGrids.push([])

  railStep: (pos, normal, binormal) ->
    return if !@numberOfRails

    for i in [0..@numberOfRails - 1]
      grid = []
      xDistance = if i % 2 == 0 then @railDistance else -@railDistance
      yDistance = if i > 1 then -@railDistance else 0

      for j in [0..@railRadialSegments]
        v = j / @railRadialSegments * 2 * Math.PI
        cx = -@railRadius * Math.cos(v) + xDistance
        cy = @railRadius * Math.sin(v) + yDistance

        _pos.copy(pos)
        _pos.x += cx * normal.x + cy * binormal.x;
        _pos.y += cx * normal.y + cy * binormal.y;
        _pos.z += cx * normal.z + cy * binormal.z;

        grid.push(@railGeometry.vertices.push(_pos.clone()) - 1)

      @_railGrids[i].push(grid)

  finalizeRails: (steps) ->
    for n in [0..@numberOfRails - 1]
      for i in [0..steps - 1]
        for j in [0..@railRadialSegments]
          ip = i + 1
          jp = (j + 1) % @railRadialSegments

          a = @_railGrids[n][i][j]
          b = @_railGrids[n][ip][j]
          c = @_railGrids[n][ip][jp]
          d = @_railGrids[n][i][jp]

          uva = new THREE.Vector2(i / steps, j / @railRadialSegments)
          uvb = new THREE.Vector2((i + 1) / steps, j / @railRadialSegments)
          uvc = new THREE.Vector2((i + 1) / steps, (j + 1) / @railRadialSegments)
          uvd = new THREE.Vector2(i / steps, (j + 1) / @railRadialSegments)

          @railGeometry.faces.push(new THREE.Face3(d, b, a))
          @railGeometry.faceVertexUvs[0].push([uva, uvb, uvd])

          @railGeometry.faces.push(new THREE.Face3(d, c, b))
          @railGeometry.faceVertexUvs[0].push([uvb.clone(), uvc, uvd.clone()])

    @railGeometry.computeCentroids()
    @railGeometry.computeFaceNormals()
    @railGeometry.computeVertexNormals()

    @railMesh = new THREE.Mesh(@railGeometry, @railMaterial)
    @railMesh.castShadow = true
    @add(@railMesh)

  ###
  # Spine Drawing
  ###

  prepareSpine: ->
    @spineGeometry = new THREE.Geometry

    if @spineShapeNeedsUpdate and @spineShape
      @spineShapeNeedsUpdate = false

      @_spineVertices = @spineShape.extractPoints(1).shape
      @_spineFaces = THREE.Shape.Utils.triangulateShape(@_spineVertices, [])

    return

  spineStep: (pos, normal, binormal) ->
    return if !@spineShape
    @_extrudeVertices(@_spineVertices, @spineGeometry.vertices, pos, normal, binormal)

  finalizeSpine: (spineSteps) ->
    @_joinFaces(@_spineVertices, @_spineFaces, @spineGeometry, spineSteps, 0, @spineGeometry.vertices.length - @_spineVertices.length)

    @spineGeometry.computeCentroids()
    @spineGeometry.computeFaceNormals()

    @spineMesh = new THREE.Mesh(@spineGeometry, @spineMaterial)
    @spineMesh.castShadow = true
    @add(@spineMesh)

  ###
  # Tie Drawing
  ###

  prepareTies: ->
    @tieGeometry = new THREE.Geometry

    if @tieShapeNeedsUpdate and @tieShape
      @tieShapeNeedsUpdate = false

      @_tieVertices = @tieShape.extractPoints(1).shape
      @_tieFaces = THREE.Shape.Utils.triangulateShape(@_tieVertices, [])

      if @extendedTieShape
        @_extendedTieVertices = @extendedTieShape.extractPoints(1).shape
        @_extendedTieFaces = THREE.Shape.Utils.triangulateShape(@_extendedTieVertices, [])

    return

  _cross = new THREE.Vector3

  tieStep: (pos, normal, binormal, useExtended) ->
    return if !@tieShape

    offset = @tieGeometry.vertices.length
    vertices = if useExtended then @_extendedTieVertices else @_tieVertices
    faces = if useExtended then @_extendedTieFaces else @_tieFaces

    _cross.crossVectors(normal, binormal).normalize()
    _cross.setLength(@tieDepth / 2).negate()
    @_extrudeVertices(vertices, @tieGeometry.vertices, pos, normal, binormal, _cross)

    _cross.negate()
    @_extrudeVertices(vertices, @tieGeometry.vertices, pos, normal, binormal, _cross)

    @_joinFaces(vertices, faces, @tieGeometry, 1, offset, vertices.length, true)

  finalizeTies: (tieSteps) ->
    @tieGeometry.computeCentroids()
    @tieGeometry.computeFaceNormals()

    @tieMesh = new THREE.Mesh(@tieGeometry, @tieMaterial)
    @tieMesh.castShadow = true
    @add(@tieMesh)

  ###
  # Helpers
  ###

  _normal = new THREE.Vector3
  _binormal = new THREE.Vector3
  _pos = new THREE.Vector3

  _extrudeVertices: (template, target, pos, normal, binormal, extra) ->
    for vertex in template
      _normal.copy(normal).multiplyScalar(vertex.x)
      _binormal.copy(binormal).multiplyScalar(vertex.y)
      _pos.copy(pos).add(_normal).add(_binormal)

      _pos.add(extra) if extra

      target.push(_pos.clone())

    return

  _joinFaces: (vertices, template, target, totalSteps, startOffset, endOffset, flipOutside) ->
    for face in template
      # Bottom
      a = face[if flipOutside then 2 else 0] + startOffset
      b = face[1] + startOffset
      c = face[if flipOutside then 0 else 2] + startOffset
      target.faces.push(new THREE.Face3(a, b, c, null, null, null))
      target.faceVertexUvs[0].push(uvgen.generateBottomUV(target, null, null, a, b, c))

      # Top
      a = face[if flipOutside then 0 else 2] + startOffset + endOffset
      b = face[1] + startOffset + endOffset
      c = face[if flipOutside then 2 else 0] + startOffset + endOffset
      target.faces.push(new THREE.Face3(a, b, c, null, null, null))
      target.faceVertexUvs[0].push(uvgen.generateTopUV(target, null, null, a, b, c))

    # Sides
    i = vertices.length
    while --i >= 0
      j = i
      k = i - 1
      k = vertices.length - 1 if k < 0

      for s in [0..totalSteps - 1]
        slen1 = vertices.length * s
        slen2 = vertices.length * (s + 1)
        a = j + slen1 + startOffset
        b = k + slen1 + startOffset
        c = k + slen2 + startOffset
        d = j + slen2 + startOffset

        target.faces.push(new THREE.Face3(d, b, a, null, null, null))
        target.faces.push(new THREE.Face3(d, c, b, null, null, null))

        uvs = uvgen.generateSideWallUV(target, null, null, null, a, b, c, d, s, totalSteps, j, k)
        target.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        target.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])

    return
