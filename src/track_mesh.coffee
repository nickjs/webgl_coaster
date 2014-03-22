class LW.TrackMesh2 extends THREE.Object3D
  constructor: (options) ->
    super()
    LW.mixin(this, options)

  updateMaterials: ->
    @wireframeMaterial ||= new THREE.LineBasicMaterial(color: 0x0000ff, linewidth: 2)
    @spineMaterial ||= new THREE.MeshPhongMaterial(color: 0xffffff, ambient: 0x090909, specular: 0x333333, shininess: 30)
    @tieMaterial ||= @spineMaterial.clone()
    @railMaterial ||= @spineMaterial.clone()

    @wireframeMaterial.color.setStyle(@model.wireframeColor)
    @spineMaterial.color.setStyle(@model.spineColor)
    @tieMaterial.color.setStyle(@model.tieColor)
    @railMaterial.color.setStyle(@model.railColor)

  rebuild: ->
    @clear()
    @meshes = []

    @model = LW.model if @model != LW.model
    return if !@model

    @wireframe = true# if @model.forceWireframe

    @updateMaterials()

    separators = @model.separators
    for separator, i in separators
      next = separators[i + 1]
      @add(new @constructor[separator.segmentType](separator, next, this))

    return

  class @TrackSegment extends THREE.Object3D
    railRadius: 1
    railDistance: 2
    railRadialSegments: 8
    numberOfRails: 2

    spineShape: null
    spineDivisionLength: 5

    tieShape: null
    tieDepth: 1

    constructor: (@separator, @next, @track) ->
      super()
      @separator.segment = this
      @rebuild()

    updateMaterials: ->
      if @separator.wireframeColor && !@wireframeMaterial
        @wireframeMaterial = @track.wireframeMaterial.clone()
      if @separator.spineColor && !@spineMaterial
        @spineMaterial = @track.spineMaterial.clone()
      if @separator.tieColor && !@tieMaterial
        @tieMaterial = @track.tieMaterial.clone()
      if @separator.railColor && !@railMaterial
        @railMaterial = @track.railMaterial.clone()

      @wireframeMaterial?.color.setStyle(@separator.wireframeColor)
      @spineMaterial?.color.setStyle(@separator.spineColor)
      @tieMaterial?.color.setStyle(@separator.tieColor)
      @railMaterial?.color.setStyle(@separator.railColor)

    rebuild: ->
      @clear()

      uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

      @updateMaterials()
      @prepareGeometries()

      model = @track.model
      spline = @track.model.spline

      totalLength = Math.ceil(spline.getLength()) * 10
      start = Math.floor(totalLength * @separator.position)
      end = Math.ceil(totalLength * (@next?.position ? 1))

      for i in [start..end]
        u = i / totalLength

        pos = spline.getPointAt(u)
        tangent = spline.getTangentAt(u).normalize()

        bank = THREE.Math.degToRad(model.getBankAt(u))
        binormal.copy(LW.UP).applyAxisAngle(tangent, bank)

        normal.crossVectors(tangent, binormal).normalize()
        binormal.crossVectors(normal, tangent).normalize()

        # if !lastSpinePos or lastSpinePos.distanceTo(pos) >= @spineDivisionLength
          # @tieStep(pos, normal, binormal, spineSteps % 7 == 0)
          # @spineStep(pos, normal, binormal)

          # if @model.debugNormals
            # @add(new THREE.ArrowHelper(normal, pos, 5, 0x00ff00))
            # @add(new THREE.ArrowHelper(binormal, pos, 5, 0x0000ff))

          # spineSteps++
          # lastSpinePos = pos

        @stepGeometries(u, pos, normal, binormal)

      # @spineStep(pos, normal, binormal)

      @finalizeGeometries()

    prepareGeometries: ->
      if @track.wireframe
        @railGeos = for i in [1..@numberOfRails]
          new THREE.Geometry
      else
        @railGeo = new THREE.Geometry

      return

    stepGeometries: (u, pos, normal, binormal) ->
      if @track.wireframe
        for geo, i in @railGeos
          distance = @railDistance
          distance = -distance if i % 2 == 0
          extrudeVertices([new THREE.Vector3(distance, 0)], geo, pos, normal, binormal)

    finalizeGeometries: ->
      if @track.wireframe
        for geo in @railGeos
          line = new THREE.Line(geo, new THREE.LineBasicMaterial(color: 0xffffff, vertexColors: THREE.VertexColors, linewidth: 2))
          @add(line)

    add: (child) ->
      child.trackSegment = true
      @track.meshes.push(child)
      super

    remove: (child) ->
      @track.meshes.splice(@track.meshes.indexOf(child), 1)
      super



class LW.TrackMesh extends THREE.Object3D
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

  wireframe: false

  constructor: (options) ->
    super()

    LW.mixin(this, options)

    @meshes = []

  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

  updateMaterials: ->
    @wireframeMaterial ||= new THREE.LineBasicMaterial(color: 0xffffff, linewidth: 2, vertexColors: THREE.VertexColors)
    @spineMaterial ||= new THREE.MeshLambertMaterial(color: 0xffffff, vertexColors: THREE.FaceColors)
    @tieMaterial ||= @spineMaterial.clone()
    @railMaterial ||= @spineMaterial.clone()

    @wireframeMaterial.color.setStyle(@model.wireframeColor)
    @spineMaterial.color.setStyle(@model.spineColor)
    @tieMaterial.color.setStyle(@model.tieColor)
    @railMaterial.color.setStyle(@model.railColor)

  add: (object) ->
    @meshes.push(object)
    object.trackSegment = true
    super

  remove: (object) ->
    @meshes.splice(@meshes.indexOf(object), 1)
    object.trackSegment = false
    super

  rebuild: ->
    @clear()

    @model = LW.model if @model != LW.model
    return if !@model

    @wireframe = true if @model.forceWireframe

    @updateMaterials()

    @prepareRails()
    @prepareTies()
    @prepareSpine()

    totalLength = Math.ceil(@model.spline.getLength())
    spineSteps = 0

    binormal = new THREE.Vector3
    normal = new THREE.Vector3

    separators = @model.separators
    segment = -1
    separator = @model.defaultSeparator
    nextSeparator = separators[0]

    @segmentWireframeColor = separator.wireframeColor = new THREE.Color(separator.wireframeColor || @model.wireframeColor)
    @segmentMeshColor = separator.meshColor = new THREE.Color(separator.spineColor || @model.spineColor)

    for i in [0..totalLength]
      u = i / totalLength

      if nextSeparator && u >= nextSeparator.position
        segment++
        separator = nextSeparator
        nextSeparator = separators[segment + 1]
        @segmentWireframeColor = separator.wireframeColor = new THREE.Color(separator.wireframeColor || @model.wireframeColor)
        @segmentMeshColor = separator.meshColor = new THREE.Color(separator.spineColor || @model.spineColor)

      pos = @model.spline.getPointAt(u)
      tangent = @model.spline.getTangentAt(u).normalize()

      bank = THREE.Math.degToRad(@model.getBankAt(u))
      binormal.copy(LW.UP).applyAxisAngle(tangent, bank)

      normal.crossVectors(tangent, binormal).normalize()
      binormal.crossVectors(normal, tangent).normalize()

      if !lastSpinePos or lastSpinePos.distanceTo(pos) >= @spineDivisionLength
        @tieStep(pos, normal, binormal, spineSteps % 7 == 0)
        @spineStep(pos, normal, binormal)

        if @model.debugNormals
          @add(new THREE.ArrowHelper(normal, pos, 5, 0x00ff00))
          @add(new THREE.ArrowHelper(binormal, pos, 5, 0x0000ff))

        spineSteps++
        lastSpinePos = pos

      @railStep(pos, normal, binormal)

    @spineStep(pos, normal, binormal)

    @finalizeRails(totalLength)
    @finalizeTies(spineSteps)
    @finalizeSpine(spineSteps)

  ###
  # Rail Drawing
  ###

  prepareRails: ->
    if @wireframe
      @railGeometries = []
      for i in [0..@numberOfRails - 1]
        @railGeometries.push(new THREE.Geometry)

    else
      @railGeometry = new THREE.Geometry

      @_railGrids = []
      for i in [0..@numberOfRails - 1]
        @_railGrids.push([])

  railStep: (pos, normal, binormal) ->
    return if !@numberOfRails

    for i in [0..@numberOfRails - 1]
      if @wireframe
        distance = @railDistance
        distance = -distance if i % 2 == 0
        oldLength = @railGeometries[i].vertices.length
        @_extrudeVertices([new THREE.Vector3(distance, 0)], @railGeometries[i].vertices, pos, normal, binormal)
        @railGeometries[i].colors.push(@segmentWireframeColor)
      else
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
    if @wireframe
      for i in [0..@numberOfRails - 1]
        @add(new THREE.Line(@railGeometries[i], @wireframeMaterial))
    else
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
    return if @wireframe

    if @spineShapeNeedsUpdate and @spineShape
      @spineShapeNeedsUpdate = false

      @_spineVertices = @spineShape.extractPoints(1).shape
      @_spineFaces = THREE.Shape.Utils.triangulateShape(@_spineVertices, [])

    return

  spineStep: (pos, normal, binormal) ->
    if @wireframe
      @_extrudeVertices(@wireframeSpine, @spineGeometry.vertices, pos, normal, binormal)
      @spineGeometry.colors.push(@segmentWireframeColor)
    else
      return if !@spineShape
      @_extrudeVertices(@_spineVertices, @spineGeometry.vertices, pos, normal, binormal)

  finalizeSpine: (spineSteps) ->
    if @wireframe
      @spineMesh = new THREE.Line(@spineGeometry, @wireframeMaterial)
    else
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
    return if @wireframe

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
    if @wireframe
      @_extrudeVertices(@wireframeTies, @tieGeometry.vertices, pos, normal, binormal)
      for i in [0..@wireframeTies.length / 2]
        @tieGeometry.colors.push(@segmentWireframeColor)
    else
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
    if @wireframe
      @tieMesh = new THREE.Line(@tieGeometry, @wireframeMaterial, THREE.LinePieces)
    else
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
      target.faces.push(new THREE.Face3(a, b, c, null, @segmentMeshColor, null))
      target.faceVertexUvs[0].push(uvgen.generateBottomUV(target, null, null, a, b, c))

      # Top
      a = face[if flipOutside then 0 else 2] + startOffset + endOffset
      b = face[1] + startOffset + endOffset
      c = face[if flipOutside then 2 else 0] + startOffset + endOffset
      target.faces.push(new THREE.Face3(a, b, c, null, @segmentMeshColor, null))
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

        target.faces.push(new THREE.Face3(d, b, a, null, @segmentMeshColor, null))
        target.faces.push(new THREE.Face3(d, c, b, null, @segmentMeshColor, null))

        uvs = uvgen.generateSideWallUV(target, null, null, null, a, b, c, d, s, totalSteps, j, k)
        target.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        target.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])

    return
