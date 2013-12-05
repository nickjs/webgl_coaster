class LW.BMTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()
    @material = new THREE.MeshLambertMaterial(color: 0xff0000, wireframe: true)

  renderRails: true

  renderTrack: ->
    @clear()

    # Shapes
    boxSize = 2
    offsetY = -3.5
    boxShape = new THREE.Shape
    boxShape.moveTo(-boxSize, -boxSize + offsetY)
    boxShape.lineTo(-boxSize, boxSize + offsetY)
    boxShape.lineTo(boxSize, boxSize + offsetY)
    boxShape.lineTo(boxSize, -boxSize + offsetY)
    boxShape.lineTo(-boxSize, -boxSize + offsetY)

    radius = 0.5
    offsetX = boxSize + 1.5
    offsetY = 0

    rail1Shape = new THREE.Shape
    rail1Shape.moveTo(offsetX + radius, offsetY)
    rail1Shape.absellipse(offsetX, offsetY, radius, radius, 0, Math.PI*2, false)
    # rail1.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    offsetX = -offsetX

    rail2Shape = new THREE.Shape
    rail2Shape.moveTo(offsetX + radius, offsetY)
    rail2Shape.absarc(offsetX, offsetY, radius, 0, Math.PI * 2, false)
    # rail2.moveTo(offsetX, offsetY + radius)
    # rail2.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    offsetX = -offsetX

    tieShape = new THREE.Shape
    tieShape.moveTo(boxSize, boxSize - 3.5 - boxSize / 4)
    tieShape.lineTo(offsetX, offsetY)
    tieShape.lineTo(offsetX - radius, offsetY)
    tieShape.lineTo(boxSize / 2, boxSize - 3)
    tieShape.lineTo(-boxSize / 2, boxSize - 3)
    tieShape.lineTo(-offsetX + radius, offsetY)
    tieShape.lineTo(-offsetX, offsetY)
    tieShape.lineTo(-boxSize, boxSize - 3.5 - boxSize / 4)

    # Meshes

    steps = @spline.getLength()

    # boxGeo = new THREE.ExtrudeGeometry(boxShape, steps: Math.floor(steps / 6), extrudePath: @spline)
    boxGeo = new LW.Extruder(@spline, spineShape: boxShape, spineSteps: Math.ceil(steps / 6), tieShape: tieShape, tieDepth: 0.65)
    boxMesh = new THREE.Mesh(boxGeo, @material)
    # boxMesh = THREE.SceneUtils.createMultiMaterialObject(boxGeo, [@material, new THREE.MeshLambertMaterial(color: 0x000000, wireframe: true, opacity: 0.5)])
    @add(boxMesh)
    # @renderRails = true

    if @renderRails
      rail1Geo = new THREE.ExtrudeGeometry(rail1Shape, steps: Math.floor(steps * 6), extrudePath: @spline)
      rail1Mesh = new THREE.Mesh(rail1Geo, @material)
      @add(rail1Mesh)

      rail2Geo = new THREE.ExtrudeGeometry(rail2Shape, steps: Math.floor(steps * 6), extrudePath: @spline)
      rail2Mesh = new THREE.Mesh(rail2Geo, @material)
      @add(rail2Mesh)


      tieSteps = Math.floor(steps / 8)
      for i in [0..tieSteps]
        mesh = new THREE.Mesh(tieProto, @material)
        mesh.position.copy(@spline.getPoint(i / tieSteps))
        @add(mesh)
