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

  constructor: (@model, options) ->
    super()

    if @model.coaster.splinePosition == 1
      @heartlineOffset = @constructor.heartlineOffset

    shapes = {}
    shapes[key] = LW.mixin({}, shape) for key, shape of @shapes
    @shapes = shapes

    @rails = rail for rail in @rails

    @stepCallbacks = {}
    LW.mixin(this, options)

    @rebuild()

  rebuild: ->
    @clear()

    return if !@model

    @prepareMaterials()

    @prepareRails()
    @prepareShapes()

    separators = @model.separators
    segment = -1
    @separator = @model.defaultSeparator
    @nextSeparator = separators[0]

    @leaveSegment(null, @separator)
    @enterSegment(@separator, @nextSeparator)

    @steps = 0
    @totalSteps = totalSteps = Math.ceil(@model.spline.getLength())

    for i in [0..totalSteps]
      u = i / totalSteps

      if @nextSeparator && u >= @nextSeparator.position
        @leaveSegment(@separator, @nextSeparator)

        segment++
        @separator = @nextSeparator
        @nextSeparator = separators[segment + 1]

        @enterSegment(@separator, @nextSeparator)

      pos = @model.spline.getPoint(u)
      matrix = LW.getMatrixAt(@model.spline, u)

      for key, func of @stepCallbacks
        func.call(this, u, pos, matrix)

      @stepRails(pos, matrix)
      @stepShapes(pos, matrix)

      @steps++

    if @model.isConnected
      @leaveSegment?(@separator)
      @separator = if separators[0].position == 0 then separators[0] else @model.defaultSeparator
      @enterSegment?(@separator)

      pos = @model.spline.getPoint(0)
      matrix = LW.getMatrixAt(@model.spline, 0)

      @stepRails(pos, matrix)
      @stepShapes(pos, matrix)

      if @shapes.spine
        @_continuousShape(@shapes.spine, pos, matrix)
        @_sideFaces(@shapes.spine)

    @finalizeRails()
    @finalizeShapes()

    @renderSupports()

  prepareMaterials: ->
    specular = 0x888888
    @railMaterial = new THREE.MeshPhongMaterial({specular, vertexColors: THREE.FaceColors})
    @shapeMaterial = new THREE.MeshPhongMaterial({specular, vertexColors: THREE.FaceColors})
    @supportMaterial = new THREE.MeshPhongMaterial({color: @model.defaultSeparator.supportColor})
    @tunnelMaterial = new THREE.MeshPhongMaterial({specular, color: @model.defaultSeparator.tunnelColor})

    liftTexture = LW.textures.chain
    liftTexture.wrapT = THREE.RepeatWrapping
    @liftMaterial = new THREE.MeshLambertMaterial(map: liftTexture)

    stationTexture = LW.textures.brick
    stationTexture.wrapS = stationTexture.wrapT = THREE.RepeatWrapping
    @stationMaterial = new THREE.MeshLambertMaterial(color: 0xcccccc, map: stationTexture)

    grateMaterial = @shapeMaterial.clone()
    grateMaterial.transparent = true
    grateMaterial.map = LW.textures.grate

    @catwalkMaterial = new THREE.MeshFaceMaterial([grateMaterial, @shapeMaterial])

    @catwalkFenceMaterial = @shapeMaterial.clone()
    @tunnelMaterial = new THREE.MeshLambertMaterial(color: @model.defaultSeparator.tunnelColor || 0xcccccc, side: THREE.DoubleSide)

  ###
  # Rail Drawing
  ###

  @rails: (newRails) ->
    final = {}

    for key of newRails
      final[key] = LW.mixin({}, @::rails[key], newRails[key])

    for key, value of @::rails
      final[key] = value if !final[key]

    return @::rails = final

  prepareRails: ->
    @railGeometry = new THREE.Geometry

    for key, rail of @rails
      rail.key ||= key
      rail._steps = 0

    return

  stepRails: (pos, matrix) ->
    color = @separator.colorObject('railColor')

    for key, rail of @rails
      if rail.disabled
        rail._steps = 0
        rail._lastGrid = null
        continue

      grid = []
      radius = rail.radius || @defaultRailRadius
      segments = rail.radialSegments || @defaultRailRadialSegments
      distance = rail.distance

      for i in [0...segments]
        v = i / segments * 2 * Math.PI
        cx = -radius * Math.cos(v) + distance.x
        cy = radius * Math.sin(v) + distance.y

        vertex = new THREE.Vector3(cx, cy, 0)
        vertex.add(@heartlineOffset).applyMatrix4(matrix).add(pos)

        grid.push(@railGeometry.vertices.push(vertex) - 1)

      if rail._steps > 0
        for i in [0...segments]
          ip = (i + 1) % segments

          a = grid[i]
          b = rail._lastGrid[i]
          c = rail._lastGrid[ip]
          d = grid[ip]

          @railGeometry.faces.push(new THREE.Face3(a, b, d, null, color))
          @railGeometry.faces.push(new THREE.Face3(b, c, d, null, color))

      rail._lastGrid = grid
      rail._steps++

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

  @shapes: (newShapes) ->
    final = {}

    for key of newShapes
      final[key] = LW.mixin({}, @::shapes[key], newShapes[key])

    for key, value of @::shapes
      final[key] = value if !final[key]

    return @::shapes = final

  prepareShapes: ->
    for key, shape of @shapes
      shape.key ||= key
      shape._steps = 0

      shape._geometry = new THREE.Geometry if shape.geometry
      continue if shape.mesh || shape.geometry

      shape.prepare = ->
        @_geometry ||= new THREE.Geometry
        @_vertices = @shape.extractPoints(1).shape
        @_faces = THREE.Shape.Utils.triangulateShape(@_vertices, [])

      shape.prepare()

    return

  stepShapes: (pos, matrix) ->
    for key, shape of @shapes
      if (shape.segment && shape.segment != @separator.type) || shape.disabled
        if shape._steps > 0
          @_bottomFace(shape, true) if !shape.open && shape._geometry && !shape.geometry
          shape._steps = 0
        if shape.disabled
          shape._wasDisabled = true
        continue

      if shape.every && shape._lastPos?.distanceTo(pos) < shape.every
        continue

      if shape.on && @shapes[shape.on]._lastPos != pos
        continue

      shape._lastPos = pos

      if shape.mesh || shape.geometry
        shape._steps++
        if shape.skipFirst
          shape.skipFirst = false
          continue

        if shape.mesh
          mesh = shape.mesh.clone()
          color = @separator.colorObject("#{shape.materialKey || shape.key}Color", 'spineColor')
          for face in mesh.geometry.faces
            face.color = color

          mesh.position.copy(pos)
          mesh.position.add(shape.offset.clone().add(@heartlineOffset).applyMatrix4(matrix)) if shape.offset
          mesh.rotation.setFromRotationMatrix(matrix)

          if shape.rotation
            mesh.rotation.x = shape.rotation.x if typeof shape.rotation.x == 'number'
            mesh.rotation.y = shape.rotation.y if typeof shape.rotation.y == 'number'
            mesh.rotation.z = shape.rotation.z if typeof shape.rotation.z == 'number'

          @add(mesh)

        else if shape.geometry
          color = @separator.colorObject("#{shape.materialKey || shape.key}Color", 'spineColor')
          faceOffset = shape._geometry.vertices.length

          q = new THREE.Quaternion
          q.setFromRotationMatrix(matrix)
          q.x = shape.rotation.x if typeof shape.rotation.x == 'number'
          q.y = shape.rotation.y if typeof shape.rotation.y == 'number'
          q.z = shape.rotation.z if typeof shape.rotation.z == 'number'

          rot = new THREE.Matrix4
          rot.makeRotationFromQuaternion(q)

          proto = shape.geometry.clone()
          proto.applyMatrix(rot)

          for vertex in proto.vertices
            newVertex = vertex.clone().add(pos)
            newVertex.add(shape.offset.clone().applyMatrix4(rot)) if shape.offset
            shape._geometry.vertices.push(newVertex)
          for face in proto.faces
            newFace = new THREE.Face3(face.a + faceOffset, face.b + faceOffset, face.c + faceOffset, face.normal, color, face.materialIndex)
            newFace.vertexNormals = face.vertexNormals
            shape._geometry.faces.push(newFace)
          for uv in proto.faceVertexUvs[0]
            shape._geometry.faceVertexUvs[0].push(uv)

          proto.dispose()

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
          @_topFace(shape, true) if steps == 1 && !shape.open
          @_sideFaces(shape) if steps > 0

    return

  _continuousShape: (shape, pos, matrix) ->
    for vertex in shape._vertices
      x = vertex.x
      y = vertex.y

      if shape.offset
        x += shape.offset.x
        y += shape.offset.y

      v = new THREE.Vector3(x, y, 0)
      v.add(@heartlineOffset)
      v.applyMatrix4(matrix)
      v.add(pos)
      shape._geometry.vertices.push(v)

    return

  _posCopy = new THREE.Vector3

  _depthShape: (shape, pos, matrix) ->
    tangent = @model.spline.getTangent(@steps / @totalSteps)
    tangent.setLength(shape.depth / 2)

    _posCopy.copy(pos)
    _posCopy.add(tangent)

    @_continuousShape(shape, _posCopy, matrix)

    _posCopy.copy(pos)
    _posCopy.add(tangent.negate())

    @_continuousShape(shape, _posCopy, matrix)

  _topFace: (shape, flip) ->
    @_shapeFaces(shape, false, true, false, flip)
  _bottomFace: (shape, flip) ->
    @_shapeFaces(shape, false, false, true, flip)
  _sideFaces: (shape, flip) ->
    @_shapeFaces(shape, true)

  _shapeFaces: (shape, sideFaces, topFace, bottomFace, flipTopBottom) ->
    color = @separator.colorObject("#{shape.materialKey || shape.key}Color", "spineColor")

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
          target.faces.push(new THREE.Face3(a, b, c, null, color, 1))
          target.faceVertexUvs[0].push(uvgen.generateBottomUV(target, shape.shape, null, a, b, c))

        if bottomFace
          a = face[if flipTopBottom then 2 else 0] + endOffset
          b = face[1] + endOffset
          c = face[if flipTopBottom then 0 else 2] + endOffset
          target.faces.push(new THREE.Face3(a, b, c, null, color, 1))
          target.faceVertexUvs[0].push(uvgen.generateTopUV(target, shape.shape, null, a, b, c))

    if sideFaces
      for i in [0...totalVertices]
        k = i - 1
        k = totalVertices - 1 if k < 0

        a = i + endOffset
        b = i + startOffset
        c = k + startOffset
        d = k + endOffset

        target.faces.push(new THREE.Face3(d, b, a, null, color, 0))
        target.faces.push(new THREE.Face3(d, c, b, null, color, 0))

        uvs = uvgen.generateSideWallUV(target, shape.shape, null, null, a, b, c, d)
        uva = new THREE.Vector2(0, 0)
        uvb = new THREE.Vector2(1, 0)
        uvc = new THREE.Vector2(0, 1)
        uvd = new THREE.Vector2(1, 1)
        target.faceVertexUvs[0].push([uvc, uvb, uvd])
        target.faceVertexUvs[0].push([uvc, uva, uvb])

    return

  finalizeShapes: ->
    for key, shape of @shapes
      if shape._geometry
        shape._geometry.computeFaceNormals()

        material = shape.material || @["#{shape.materialKey || shape.key}Material"] || @shapeMaterial
        shape.mesh = new THREE.Mesh(shape._geometry, material)
        shape.mesh.castShadow = true
        shape.mesh.receiveShadow = true if shape.receiveShadow

        @add(shape.mesh)

    return

  ###
  # Supports
  ###

  supportOffset: new THREE.Vector3(0, -4, 0)

  renderSupports: ->
    footerTexture = LW.textures.footer
    footerBump = LW.textures.footerBump

    footerTexture.anisotropy = 4
    footerBump.anisotropy = 4
    textureMaterial = new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111, map: footerTexture, bumpMap: footerBump, bumpScale: 20, metal: true)
    colorMaterial = new THREE.MeshLambertMaterial(color: 0x737373)
    footerMaterial = new THREE.MeshFaceMaterial([textureMaterial, colorMaterial])

    size = 7
    footerGeo = new THREE.Geometry
    geo = new THREE.BoxGeometry(size, LW.FoundationNode::height, size)
    for face, i in geo.faces
      if i in [4, 5]
        face.materialIndex = 0
      else
        face.materialIndex = 1

    for node in @model.foundationNodes
      node.position.y = 1000
      ray = new THREE.Raycaster(node.position, LW.DOWN, 1, 2000)
      point = ray.intersectObject(LW.terrain.ground)[0]
      node.position.y = point.point.y - node.offsetHeight + 1.5

      faceOffset = footerGeo.vertices.length
      for vertex in geo.vertices
        footerGeo.vertices.push(vertex.clone().add(node.position))
      for face in geo.faces
        newFace = new THREE.Face3(face.a + faceOffset, face.b + faceOffset, face.c + faceOffset, face.normal, face.color, face.materialIndex)
        newFace.vertexNormals = face.vertexNormals
        footerGeo.faces.push(newFace)
      for uv in geo.faceVertexUvs[0]
        footerGeo.faceVertexUvs[0].push(uv)

    mesh = new THREE.Mesh(footerGeo, footerMaterial)
    @add(mesh)

    for node in @model.trackConnectionNodes
      continue if typeof node.position != "number"

      pos = @model.spline.getPoint(node.position)
      matrix = LW.getMatrixAt(@model.spline, node.position)

      node.position = pos.clone()
      node.position.add(@supportOffset.clone().applyMatrix4(matrix))

    orientation = new THREE.Matrix4
    offsetRotation = new THREE.Matrix4
    offsetPosition = new THREE.Matrix4
    p1 = new THREE.Vector3
    p2 = new THREE.Vector3
    delta = new THREE.Vector3

    spineMesh = @shapes.spine?.mesh
    supportGeo = new THREE.Geometry

    for tube in @model.supportTubes
      p1.copy(tube.node1.position)
      p2.copy(tube.node2.position)

      p1.y += tube.node1.offsetHeight
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

      faceOffset = supportGeo.vertices.length
      for vertex in geo.vertices
        supportGeo.vertices.push(vertex.clone().add(position))
      for face in geo.faces
        newFace = new THREE.Face3(face.a + faceOffset, face.b + faceOffset, face.c + faceOffset, face.normal)
        newFace.vertexNormals = face.vertexNormals
        supportGeo.faces.push(newFace)

      geo.dispose()

    # supportGeo.mergeVertices()
    supportMesh = new THREE.Mesh(supportGeo, @supportMaterial)
    @add(supportMesh)

  ###
  # Extras
  ###

  liftShape = new THREE.Shape
  liftShape.moveTo(-0.7, -0.3)
  liftShape.lineTo(-0.7, 0.3)
  liftShape.lineTo(0.7, 0.3)
  liftShape.lineTo(0.7, -0.3)

  gearGeometry = new THREE.CylinderGeometry(3, 3, 1.35)
  gearGeometry.applyMatrix(new THREE.Matrix4().makeRotationZ(Math.PI / 2))
  gearGeometry: gearGeometry

  gearOffset: new THREE.Vector3(-0.7, 2.25, 0)

  stationShape = new THREE.Shape
  stationShape.moveTo(-30, -500)
  stationShape.lineTo(-30, 3)
  stationShape.lineTo(-6, 3)
  stationShape.lineTo(-6, -7)
  stationShape.lineTo(6, -7)
  stationShape.lineTo(6, 3)
  stationShape.lineTo(30, 3)
  stationShape.lineTo(30, -500)

  catwalkStep = new THREE.BoxGeometry(10, 0.4, 3.95)
  for face, i in catwalkStep.faces
    if i in [4, 5, 6, 7]
      face.materialIndex = 0
    else
      face.materialIndex = 1

  catwalkShape = new THREE.Shape
  catwalkShape.moveTo(-5, 0)
  catwalkShape.lineTo(5, 0)
  catwalkShape.lineTo(5, -0.4)
  catwalkShape.lineTo(-5, -0.4)

  catwalkCenterShape = new THREE.Shape
  catwalkCenterShape.moveTo(-4.5, 0)
  catwalkCenterShape.lineTo(4.5, 0)
  catwalkCenterShape.lineTo(4.5, -0.4)
  catwalkCenterShape.lineTo(-4.5, -0.4)

  catwalkRailing = new THREE.Shape
  catwalkRailing.moveTo(-0.25, -0.5)
  catwalkRailing.lineTo(-0.25, 0)
  catwalkRailing.lineTo(0, 0)
  catwalkRailing.lineTo(0, 3.5)
  catwalkRailing.lineTo(-0.25, 3.5)
  catwalkRailing.lineTo(-0.25, 4)
  catwalkRailing.lineTo(0, 4)
  catwalkRailing.lineTo(0, 7.5)
  catwalkRailing.lineTo(-0.25, 7.5)
  catwalkRailing.lineTo(-0.25, 8)
  catwalkRailing.lineTo(0.25, 8)
  catwalkRailing.lineTo(0.25, 7.5)
  catwalkRailing.lineTo(0.1, 7.5)
  catwalkRailing.lineTo(0.1, 4)
  catwalkRailing.lineTo(0.25, 4)
  catwalkRailing.lineTo(0.25, 3.5)
  catwalkRailing.lineTo(0.1, 3.5)
  catwalkRailing.lineTo(0.1, 0)
  catwalkRailing.lineTo(0.25, 0)
  catwalkRailing.lineTo(0.25, -0.5)

  tunnelRadius = 9
  squareTunnel = new THREE.Shape
  squareTunnel.moveTo(-tunnelRadius, -5.5)
  squareTunnel.lineTo(tunnelRadius, -5.5)
  squareTunnel.lineTo(tunnelRadius, tunnelRadius + 5)
  squareTunnel.lineTo(-tunnelRadius, tunnelRadius + 5)

  @shapes {
    lift: {shape: liftShape, segment: 'LiftSegment'}
    station: {shape: stationShape, every: 10, segment: 'StationSegment'}
    catwalkStepsLeft: {geometry: catwalkStep, every: 4, offset: new THREE.Vector3(-7.5, -4, 0), rotation: {x: 0, z: 0}, materialKey: 'catwalk', receiveShadow: true}
    catwalkStepsRight: {geometry: catwalkStep, every: 4, offset: new THREE.Vector3(7.5, -4, 0), rotation: {x: 0, z: 0}, materialKey: 'catwalk', receiveShadow: true}
    catwalkLeft: {shape: catwalkShape, every: 10, offset: new THREE.Vector2(-7.5, -3), materialKey: 'catwalk'}
    catwalkRight: {shape: catwalkShape, every: 10, offset: new THREE.Vector2(7.5, -3), materialKey: 'catwalk'}
    catwalkRailingLeft: {shape: catwalkRailing, every: 10, offset: new THREE.Vector2(-12.5, -4), materialKey: 'catwalkFence'}
    catwalkRailingRight: {shape: catwalkRailing, every: 10, offset: new THREE.Vector2(12.5, -4), materialKey: 'catwalkFence'}
    catwalkCenter: {shape: catwalkCenterShape, every: 10, offset: new THREE.Vector2(0, -3), materialKey: 'catwalk'}
    squareTunnel: {shape: squareTunnel, every: 10, open: true, materialKey: 'tunnel', receiveShadow: true}
  }

  enterSegment: (segment) ->
    railingLeft = segment.settings.railing_left
    railingRight = segment.settings.railing_right
    if railingLeft || railingRight
      @stepCallbacks.decideOnCatwalks ||= (u) ->
        tangent = @model.spline.getTangent(u)
        flatAngle = Math.PI / 2
        tangentAngle = Math.abs(LW.DOWN.angleTo(tangent))
        flat = Math.abs(tangentAngle - flatAngle) < 0.4

        @shapes.catwalkLeft.disabled = !railingLeft || !flat
        @shapes.catwalkRight.disabled = !railingRight || !flat
        @shapes.catwalkStepsLeft.disabled = !railingLeft || flat
        @shapes.catwalkStepsRight.disabled = !railingRight || flat
        @shapes.catwalkRailingLeft.disabled = !railingLeft
        @shapes.catwalkRailingRight.disabled = !railingRight

        @shapes.catwalkCenter.disabled = !railingLeft || !railingRight || !@shapes.catwalkCenter.enabled
    else if @stepCallbacks.decideOnCatwalks
      delete @stepCallbacks.decideOnCatwalks

    @shapes.squareTunnel.disabled = !segment.settings.use_tunnel

  leaveSegment: (segment) ->
    @shapes.catwalkLeft.disabled = true
    @shapes.catwalkRight.disabled = true
    @shapes.catwalkStepsLeft.disabled = true
    @shapes.catwalkStepsRight.disabled = true
    @shapes.catwalkRailingLeft.disabled = true
    @shapes.catwalkRailingRight.disabled = true
    @shapes.catwalkCenter.disabled = true
