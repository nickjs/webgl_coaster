class LW.BMTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()
    @material = new THREE.MeshLambertMaterial(color: 0xff0000, wireframe: true)

  renderTrack: ->
    # Shapes
    boxSize = 2
    boxShape = new THREE.Shape
    boxShape.moveTo(-boxSize, -boxSize)
    boxShape.lineTo(-boxSize, boxSize)
    boxShape.lineTo(boxSize, boxSize)
    boxShape.lineTo(boxSize, -boxSize)
    boxShape.lineTo(-boxSize, -boxSize)

    radius = 0.5
    offsetX = boxSize + 1.5
    offsetY = boxSize * 2 - 0.5

    rail1Shape = new THREE.Shape
    rail1Shape.moveTo(offsetX + radius, offsetY)
    rail1Shape.absellipse(offsetX, offsetY, radius, radius, 0, Math.PI*2, false)
    # rail1.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    offsetX = -boxSize - 1.5

    rail2Shape = new THREE.Shape
    rail2Shape.moveTo(offsetX + radius, offsetY)
    rail2Shape.absarc(offsetX, offsetY, radius, 0, Math.PI * 2, false)
    # rail2.moveTo(offsetX, offsetY + radius)
    # rail2.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    # Meshes

    steps = @spline.getLength()

    boxGeo = new THREE.ExtrudeGeometry(boxShape, steps: Math.floor(steps / 6), extrudePath: @spline)
    boxMesh = new THREE.Mesh(boxGeo, @material)
    # boxMesh = THREE.SceneUtils.createMultiMaterialObject(@boxGeo, [mat, wireMat])
    @add(boxMesh)

    rail1Geo = new THREE.ExtrudeGeometry(rail1Shape, steps: Math.floor(steps * 6), extrudePath: @spline)
    rail1Mesh = new THREE.Mesh(rail1Geo, @material)
    @add(rail1Mesh)

    rail2Geo = new THREE.ExtrudeGeometry(rail2Shape, steps: Math.floor(steps * 6), extrudePath: @spline)
    rail2Mesh = new THREE.Mesh(rail2Geo, @material)
    @add(rail2Mesh)
