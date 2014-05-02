class LW.TrackMesh extends THREE.Object3D
  rails: []
  defaultRailRadius: 1
  defaultRailRadialSegments: 8

  ###
  shape options: {
    shape: THREE.Shape instance to extrude
    segment: only extrude this shape while on segments of this type
    every: distance between extrusion points
    depth: requires every, extrudes shape over x depth every y distance
    offset: Vector2 offset to apply to this shape
    colorKey: the key of the color to query the separator for this shape
  }
  ###
  shapes: {}

  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

  constructor: (options) ->
    super()
    LW.mixin(this, options)

  rebuild: ->
    @clear()

    @model = LW.model if @model != LW.model
    return if !@model

    @prepareMaterials()

    @prepareRails()
    @prepareShapes()

    separators = @model.separators
    segment = -1
    @separator = @model.defaultSeparator
    @nextSeparator = separators[0]

    @steps = 0
    @totalSteps = totalSteps = Math.ceil(@model.spline.getLength())

    for i in [0..totalSteps]
      u = i / totalSteps

      if @nextSeparator && u >= @nextSeparator.position
        @leaveSegment?(@separator)

        segment++
        @separator = @nextSeparator
        @nextSeparator = separators[segment + 1]

        @enterSegment?(@separator)

      pos = @model.spline.getPointAt(u)
      matrix = LW.getMatrixAt(@model.spline, u)

      @stepRails(pos, matrix)
      @stepShapes(pos, matrix)

      @steps++

    if @model.isConnected
      @leaveSegment?(@separator)
      @separator = if separators[0].position == 0 then separators[0] else @model.defaultSeparator
      @enterSegment?(@separator)

      pos = @model.spline.getPointAt(0)
      matrix = LW.getMatrixAt(@model.spline, 0)

      @stepRails(pos, matrix)
      @stepShapes(pos, matrix)

      if @shapes.spine
        @_continuousShape(@shapes.spine, pos, matrix)
        @_shapeFaces(@shapes.spine, true)

    @finalizeRails()
    @finalizeShapes()

    @renderSupports()

  prepareMaterials: ->
    specular = 0x888888
    @railMaterial = new THREE.MeshPhongMaterial({specular, color: @model.defaultSeparator.railColor, vertexColors: THREE.FaceColors})
    @shapeMaterial = new THREE.MeshPhongMaterial({specular, color: @model.defaultSeparator.spineColor, vertexColors: THREE.FaceColors})
    @supportMaterial = new THREE.MeshPhongMaterial({color: @model.defaultSeparator.supportColor})

  ###
  # Rail Drawing
  ###

  prepareRails: ->
    @railGeometry = new THREE.Geometry

  stepRails: (pos, matrix) ->
    color = @separator.colorObject('railColor')

    for rail in @rails
      grid = []
      radius = rail.radius || @defaultRailRadius
      segments = rail.radialSegments || @defaultRailRadialSegments
      distance = rail.distance

      for i in [0...segments]
        v = i / segments * 2 * Math.PI
        cx = -radius * Math.cos(v) + distance.x
        cy = radius * Math.sin(v) + distance.y

        vertex = new THREE.Vector3(cx, cy, 0)
        vertex.applyMatrix4(matrix).add(pos)

        grid.push(@railGeometry.vertices.push(vertex) - 1)

      if @steps > 0
        for i in [0...segments]
          ip = (i + 1) % segments

          a = grid[i]
          b = rail._lastGrid[i]
          c = rail._lastGrid[ip]
          d = grid[ip]

          @railGeometry.faces.push(new THREE.Face3(a, b, d, null, color))
          @railGeometry.faces.push(new THREE.Face3(b, c, d, null, color))

      rail._lastGrid = grid

    return

  finalizeRails: ->
    @railGeometry.computeFaceNormals()
    @railGeometry.computeVertexNormals()

    @railMesh = new THREE.Mesh(@railGeometry, @railMaterial)
    @railMesh.castShadow = true

    @add(@railMesh)

  ###
  # Shape Drawing
  ###

  prepareShapes: ->
    for key, shape of @shapes
      shape.key ||= key
      shape._steps = 0

      continue if shape.mesh

      shape.prepare = ->
        @_geometry ||= new THREE.Geometry
        @_vertices = @shape.extractPoints(1).shape
        @_faces = THREE.Shape.Utils.triangulateShape(@_vertices, [])

      shape.prepare()

    return

  stepShapes: (pos, matrix) ->
    for key, shape of @shapes
      if shape.disabled
        shape._wasDisabled = true
        continue

      if shape.segment && shape.segment != @separator.type
        if shape._steps > 0
          @_shapeFaces(shape, false, false, true, true)
          shape._steps = 0
        continue

      if shape.every && shape._lastPos?.distanceTo(pos) < shape.every
        continue

      shape._lastPos = pos

      if shape.mesh
        shape._steps++
        if shape.skipFirst
          shape.skipFirst = false
          continue

        mesh = shape.mesh.clone()
        mesh.position.copy(pos)
        mesh.rotation.setFromRotationMatrix(matrix)
        @add(mesh)

      else if shape.depth
        @_depthShape(shape, pos, matrix)
        @_shapeFaces(shape, true, true, true)
        shape._steps += 2

      else
        steps = shape._steps++
        @_continuousShape(shape, pos, matrix)
        if shape._wasDisabled
          shape._wasDisabled = false
        else
          @_shapeFaces(shape, true, steps == 1, false, true) if steps > 0

    return

  _continuousShape: (shape, pos, matrix) ->
    for vertex in shape._vertices
      x = vertex.x
      y = vertex.y

      if shape.offset
        x += shape.offset.x
        y += shape.offset.y

      v = new THREE.Vector3(x, y, 0)
      v.applyMatrix4(matrix)
      v.add(pos)
      shape._geometry.vertices.push(v)

    return

  _posCopy = new THREE.Vector3

  _depthShape: (shape, pos, matrix) ->
    tangent = @model.spline.getTangentAt(@steps / @totalSteps)
    tangent.setLength(shape.depth / 2)

    _posCopy.copy(pos)
    _posCopy.add(tangent)

    @_continuousShape(shape, _posCopy, matrix)

    _posCopy.copy(pos)
    _posCopy.add(tangent.negate())

    @_continuousShape(shape, _posCopy, matrix)

  _shapeFaces: (shape, sideFaces, topFace, bottomFace, flipTopBottom) ->
    color = @separator.colorObject("#{shape.key}Color")

    target = shape._geometry
    totalVertices = shape._vertices.length
    endOffset = target.vertices.length - totalVertices
    startOffset = endOffset - totalVertices

    if topFace || bottomFace
      for face in shape._faces
        if topFace
          a = face[if flipTopBottom then 0 else 2] + startOffset
          b = face[1] + startOffset
          c = face[if flipTopBottom then 2 else 0] + startOffset
          target.faces.push(new THREE.Face3(a, b, c, null, color))
          target.faceVertexUvs[0].push(uvgen.generateBottomUV(target, shape.shape, null, a, b, c))

        if bottomFace
          a = face[if flipTopBottom then 2 else 0] + endOffset
          b = face[1] + endOffset
          c = face[if flipTopBottom then 0 else 2] + endOffset
          target.faces.push(new THREE.Face3(a, b, c, null, color))
          target.faceVertexUvs[0].push(uvgen.generateTopUV(target, shape.shape, null, a, b, c))

    if sideFaces
      for i in [0...totalVertices]
        k = i - 1
        k = totalVertices - 1 if k < 0

        a = i + endOffset
        b = i + startOffset
        c = k + startOffset
        d = k + endOffset

        target.faces.push(new THREE.Face3(d, b, a, null, color))
        target.faces.push(new THREE.Face3(d, c, b, null, color))

        uvs = uvgen.generateSideWallUV(target, shape.shape, null, null, a, b, c, d)
        target.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        target.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])

    return

  finalizeShapes: ->
    for key, shape of @shapes
      if shape._geometry
        shape._geometry.computeFaceNormals()
        shape.mesh = new THREE.Mesh(shape._geometry, shape.material || @["#{shape.key}Material"] || @shapeMaterial)
        @add(shape.mesh)

      shape.mesh.castShadow = true

    return

  ###
  # Supports
  ###

  renderSupports: ->
    footerTexture = LW.textures.footer
    footerBump = LW.textures.footerBump

    footerTexture.anisotropy = 4
    footerBump.anisotropy = 4
    footerMaterial = new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111, map: footerTexture, bumpMap: footerBump, bumpScale: 20, metal: true)

    size = 7
    geo = new THREE.BoxGeometry(size, LW.FoundationNode::height, size)

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

    spineMesh = @shapes.spine?.mesh

    for tube in @model.supportTubes
      p1.copy(tube.node1.position)
      p2.copy(tube.node2.position)

      if tube.node1 instanceof LW.TrackConnectionNode
        delta.subVectors(p1, p2).normalize()
        ray = new THREE.Raycaster(p2, delta, 1, 1000)
        point = ray.intersectObject(spineMesh)[0]
        p1.copy(point.point) if point?.point
      else
        p1.y += tube.node1.offsetHeight

      if tube.node2 instanceof LW.TrackConnectionNode
        delta.subVectors(p2, p1).normalize()
        ray = new THREE.Raycaster(p1, delta, 1, 1000)
        point = ray.intersectObject(spineMesh)[0]
        p2.copy(point.point) if point?.point
      else
        p2.y += tube.node2.offsetHeight

      height = p1.distanceTo(p2)
      continue if height < 0.5

      if tube.isBox
        geo = new THREE.BoxGeometry(tube.size, height, tube.size)
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
