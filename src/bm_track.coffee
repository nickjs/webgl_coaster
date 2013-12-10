class LW.BMTrack extends LW.Track
  boxSize = 2
  offsetY = -3

  boxShape = new THREE.Shape
  boxShape.moveTo(-boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, -boxSize + offsetY)

  spineShape: boxShape
  spineDivisionLength: 7

  radius = 0.5
  offsetX = boxSize + 2
  offsetY = 0
  padding = boxSize / 4

  tieShape = new THREE.Shape
  tieShape.moveTo(boxSize, boxSize - 3 - padding)
  tieShape.lineTo(offsetX - radius * 1.5, offsetY)
  tieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75)
  tieShape.lineTo(boxSize / 2, boxSize - 2.5)
  tieShape.lineTo(-boxSize / 2, boxSize - 2.5)
  tieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75)
  tieShape.lineTo(-offsetX + radius * 1.5, offsetY)
  tieShape.lineTo(-boxSize, boxSize - 3 - padding)

  tieShape: tieShape

  tieShape = new THREE.Shape
  tieShape.moveTo(boxSize + padding, boxSize - 3 - padding)
  tieShape.lineTo(offsetX - radius * 1.5, offsetY)
  tieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75)
  tieShape.lineTo(boxSize / 2, boxSize - 2.5)
  tieShape.lineTo(-boxSize / 2, boxSize - 2.5)
  tieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75)
  tieShape.lineTo(-offsetX + radius * 1.5, offsetY)
  tieShape.lineTo(-boxSize - padding, boxSize - 3 - padding)
  tieShape.lineTo(-boxSize - padding, -boxSize - 3 - padding)
  tieShape.lineTo(boxSize + padding, -boxSize - 3 - padding)

  extendedTieShape: tieShape
  tieDepth: 0.4

  railRadius: radius
  railDistance: offsetX - radius

  liftShape = new THREE.Shape
  liftShape.moveTo(boxSize / 2, 0)
  liftShape.lineTo(boxSize / 2, 0.5)
  # liftShape.lineTo(boxSize / 4, 0.5)
  # liftShape.moveTo(-boxSize / 4, 0.5)
  liftShape.lineTo(-boxSize / 2, 0.5)
  liftShape.lineTo(-boxSize / 2, 0)
  liftShape: liftShape

  constructor: ->
    super

    @spineMaterial = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)
    @tieMaterial = @spineMaterial.clone()
    @railMaterial = @spineMaterial.clone()

    @materials = [@spineMaterial, @tieMaterial, @railMaterial]

