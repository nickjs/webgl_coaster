class LW.BMTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()
    @material = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)

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

    numberOfRails = if @renderRails then 2 else 0
    boxGeo = new LW.Extruder(@spline, spineShape: boxShape, spineSteps: Math.ceil(steps / 8), tieShape: tieShape, tieDepth: 0.65, numberOfRails: numberOfRails, railRadius: radius, railDistance: offsetX - radius)
    boxMesh = new THREE.Mesh(boxGeo, @material)
    boxMesh.castShadow = true
    boxMesh.receiveShadow = true
    @add(boxMesh)
