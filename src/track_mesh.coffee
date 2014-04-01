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
    @spineMaterial ||= new THREE.MeshPhongMaterial(color: 0xffffff, shininess: 40, vertexColors: THREE.FaceColors)
    @tieMaterial ||= @spineMaterial.clone()
    @railMaterial ||= @spineMaterial.clone()
    @supportMaterial ||= @spineMaterial.clone()

    @wireframeMaterial.color.setStyle(@model.wireframeColor)
    @spineMaterial.color.setStyle(@model.spineColor)
    @spineMaterial.specular.setStyle(@model.spineColor)
    @tieMaterial.color.setStyle(@model.tieColor)
    @railMaterial.color.setStyle(@model.railColor)
    @supportMaterial.color.setStyle(@model.supportColor)

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
    @prepareExtras()

    totalLength = Math.ceil(@model.spline.getLength())
    spineSteps = 0

    up = LW.UP.clone()
    rolledUp = up.clone()
    binormal = new THREE.Vector3

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

      [bank, relative] = @model.getBankAt(u)

      if relative
        binormal.crossVectors(tangent, up).normalize()
        up.crossVectors(binormal, tangent).normalize()

        rolledUp.copy(up).applyAxisAngle(tangent, bank).normalize()
        binormal.crossVectors(tangent, rolledUp).normalize()
      else
        up.copy(LW.UP).applyAxisAngle(tangent, bank)

        binormal.crossVectors(tangent, up).normalize()
        up.crossVectors(binormal, tangent).normalize()
        rolledUp.copy(up)

      matrix = new THREE.Matrix4(binormal.x, rolledUp.x, -tangent.x, 0,
                                 binormal.y, rolledUp.y, -tangent.y, 0,
                                 binormal.z, rolledUp.z, -tangent.z, 0
                                 0, 0, 0, 1)

      if !lastSpinePos or lastSpinePos.distanceTo(pos) >= @spineDivisionLength
        @tieStep(pos, binormal, rolledUp, matrix, spineSteps % 7 == 0)
        @spineStep(pos, matrix)

        if @model.debugNormals
          @add(new THREE.ArrowHelper(tangent, pos, 5, 0xff0000))
          @add(new THREE.ArrowHelper(binormal, pos, 5, 0x00ff00))
          @add(new THREE.ArrowHelper(rolledUp, pos, 5, 0x0000ff))

        spineSteps++
        lastSpinePos = pos

      @railStep(pos, binormal, rolledUp)
      @extrasStep(pos, matrix, separator.type)

    @spineStep(pos, matrix)

    @finalizeRails(totalLength)
    @finalizeTies(spineSteps)
    @finalizeSpine(spineSteps)
    @finalizeExtras(totalLength)

    @renderSupports()

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
        xDistance = 0 if @numberOfRails == 3 && i == 2
        yDistance = if i >= 2 then -@railDistance * 2 else 0

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

    if @spineShapeNeedsUpdate && @spineShape
      @spineShapeNeedsUpdate = false

      @_spineVertices = @spineShape.extractPoints(1).shape
      @_spineFaces = THREE.Shape.Utils.triangulateShape(@_spineVertices, [])

    return

  spineStep: (pos, matrix) ->
    if @wireframe
      @_extrudeVertices(@wireframeSpine, @spineGeometry.vertices, pos, matrix)
      @spineGeometry.colors.push(@segmentWireframeColor)
    else if @spineShape
      @_extrudeVertices(@_spineVertices, @spineGeometry.vertices, pos, matrix)

  finalizeSpine: (spineSteps) ->
    if @wireframe
      @spineMesh = new THREE.Line(@spineGeometry, @wireframeMaterial)
    else
      return if !@spineShape
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

  tieStep: (pos, normal, binormal, matrix, useExtended) ->
    if @wireframe
      @_extrudeVertices(@wireframeTies, @tieGeometry.vertices, pos, normal, binormal)
      for i in [0..@wireframeTies.length / 2]
        @tieGeometry.colors.push(@segmentWireframeColor)
    else if @tieShape
      iterations = if @numberOfRails == 2 then 1 else @numberOfRails
      for i in [0...iterations]
        offset = @tieGeometry.vertices.length
        vertices = if useExtended then @_extendedTieVertices else @_tieVertices
        faces = if useExtended then @_extendedTieFaces else @_tieFaces

        if i > 0
          pos = pos.clone()
          pos.y -= 2

        _cross.crossVectors(normal, binormal).normalize()
        _cross.setLength(@tieDepth / 2).negate()
        @_extrudeVertices(vertices, @tieGeometry.vertices, pos, matrix, _cross)

        _cross.negate()
        @_extrudeVertices(vertices, @tieGeometry.vertices, pos, matrix, _cross)

        @_joinFaces(vertices, faces, @tieGeometry, 1, offset, vertices.length, true)

  finalizeTies: (tieSteps) ->
    if @wireframe
      @tieMesh = new THREE.Line(@tieGeometry, @wireframeMaterial, THREE.LinePieces)
      @add(@tieMesh)
    else if @tieShape
      @tieGeometry.computeCentroids()
      @tieGeometry.computeFaceNormals()

      @tieMesh = new THREE.Mesh(@tieGeometry, @tieMaterial)
      @tieMesh.castShadow = true

      @add(@tieMesh)

  ###
  # Extras
  ###

  prepareExtras: ->
    @extraGeometry = new THREE.Geometry

    if @liftShape
      @_liftSteps = 0
      @_liftVertices = @liftShape.extractPoints(1).shape
      @_liftFaces = THREE.Shape.Utils.triangulateShape(@_liftVertices, [])

  extrasStep: (pos, matrix, segmentType) ->
    return if !@liftShape
    if segmentType == LW.Separator.TYPE.LIFT
      @_extrudeVertices(@_liftVertices, @extraGeometry.vertices, pos, matrix)
      @_liftSteps++

  finalizeExtras: (totalLength) ->
    # Sides
    return if @_liftSteps < 3 || !@liftShape
    vertices = @_liftVertices
    target = @extraGeometry
    i = vertices.length
    while --i >= 0
      j = i
      k = i - 1
      k = vertices.length - 1 if k < 0

      for s in [0..@_liftSteps - 3]
        slen1 = vertices.length * s
        slen2 = vertices.length * (s + 1)
        a = j + slen1
        b = k + slen1
        c = k + slen2
        d = j + slen2

        target.faces.push(new THREE.Face3(a, b, d, null, null, null))
        target.faces.push(new THREE.Face3(b, c, d, null, null, null))

        uvs = uvgen.generateSideWallUV(target, null, null, null, a, b, c, d, s, @_liftSteps - 2, j, k)
        target.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        target.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])

    @extraGeometry.computeCentroids()
    @extraGeometry.computeFaceNormals()

    @liftMaterial = new THREE.MeshLambertMaterial(color: 0xffffff)
    texture1 = THREE.ImageUtils.loadTexture @liftTexture || "#{BASE_URL}/textures/chain.png", undefined, =>
      texture1.wrapT = THREE.RepeatWrapping
      texture1.offset.setX(0.5)
      @liftMaterial.map = texture1

      @extraMesh = new THREE.Mesh(@extraGeometry, @liftMaterial)
      @add(@extraMesh)

    mat = new THREE.MeshLambertMaterial(color: 0x444444)
    @gears = []

    gearMesh = new THREE.Mesh(@gearGeometry, mat)
    gearMesh.position = @extraGeometry.vertices[0].clone().sub(@gearOffset)
    @gears.push(gearMesh)
    @add(gearMesh)

    gearMesh = new THREE.Mesh(@gearGeometry, mat)
    gearMesh.position = @extraGeometry.vertices[@extraGeometry.vertices.length - 3].clone().sub(@gearOffset)
    @gears.push(gearMesh)
    @add(gearMesh)

  ###
  # Supports
  ###

  renderSupports: ->
    footerTexture = THREE.ImageUtils.loadTexture "#{BASE_URL}/textures/footer.jpg", undefined, =>
      footerBump = THREE.ImageUtils.loadTexture "#{BASE_URL}/textures/footer-bump.png", undefined, =>

        footerTexture.anisotropy = 4
        footerBump.anisotropy = 4
        footerMaterial = new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111, map: footerTexture, bumpMap: footerBump, bumpScale: 20, metal: true)

        size = 7
        geo = new THREE.CubeGeometry(size, LW.FoundationNode::height, size)

        for node in @model.foundationNodes
          mesh = new THREE.Mesh(geo, footerMaterial)

          node.position.y = 1000
          ray = new THREE.Raycaster(node.position, LW.DOWN, 1, 2000)
          point = ray.intersectObject(LW.terrain.ground)[0]
          node.position.y = point.point.y - node.offsetHeight + 1.5

          mesh.position = node.position
          @add(mesh)

        orientation = new THREE.Matrix4
        offsetRotation = new THREE.Matrix4
        offsetPosition = new THREE.Matrix4
        p1 = new THREE.Vector3
        p2 = new THREE.Vector3
        delta = new THREE.Vector3

        for tube in @model.supportTubes
          p1.copy(tube.node1.position)
          p2.copy(tube.node2.position)

          if tube.node1 instanceof LW.TrackConnectionNode
            delta.subVectors(p1, p2).normalize()
            ray = new THREE.Raycaster(p2, delta, 1, 1000)
            point = ray.intersectObject(@spineMesh)[0]
            p1.copy(point.point) if point?.point
          else
            p1.y += tube.node1.offsetHeight

          if tube.node2 instanceof LW.TrackConnectionNode
            delta.subVectors(p2, p1).normalize()
            ray = new THREE.Raycaster(p1, delta, 1, 1000)
            point = ray.intersectObject(@spineMesh)[0]
            p2.copy(point.point) if point?.point
          else
            p2.y += tube.node2.offsetHeight

          height = p1.distanceTo(p2)
          continue if height < 0.5

          if tube.isBox
            geo = new THREE.CubeGeometry(tube.size, height, tube.size)
          else
            geo = new THREE.CylinderGeometry(tube.size, tube.size, height)

          position = p2.clone().add(p1).divideScalar(2)
          orientation.lookAt(p1, p2, LW.UP)
          offsetRotation.makeRotationX(Math.PI / 2)
          orientation.multiply(offsetRotation)
          geo.applyMatrix(orientation)

          mesh = new THREE.Mesh(geo, @supportMaterial)
          mesh.position = position
          mesh.castShadow = true
          @add(mesh)

  ###
  # Helpers
  ###

  _extrudeVertices: (template, target, pos, matrix, extra) ->
    for vertex in template
      v = new THREE.Vector3(vertex.x, vertex.y, 0)
      v.applyMatrix4(matrix)
      v.add(pos)
      v.add(extra) if extra
      target.push(v)
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
