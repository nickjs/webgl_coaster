class LW.BMTrack extends LW.Track
  boxSize = 2
  offsetY = -3.2

  boxShape = new THREE.Shape
  boxShape.moveTo(-boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, -boxSize + offsetY)

  spineShape: boxShape
  spineDivisionLength: 7

  radius = 0.5
  offsetX = boxSize + 1.5
  offsetY = 0

  tieShape = new THREE.Shape
  tieShape.moveTo(boxSize, boxSize - 3.5 - boxSize / 4)
  tieShape.lineTo(offsetX - radius, offsetY - radius)
  tieShape.lineTo(offsetX - radius, offsetY)
  tieShape.lineTo(boxSize / 3, boxSize - 2.5)
  tieShape.lineTo(-boxSize / 3, boxSize - 2.5)
  tieShape.lineTo(-offsetX + radius, offsetY)
  tieShape.lineTo(-offsetX + radius, offsetY - radius)
  tieShape.lineTo(-boxSize, boxSize - 3.5 - boxSize / 4)

  tieShape: tieShape

  tieShape = new THREE.Shape
  padding = boxSize / 4
  tieShape.moveTo(boxSize + padding, boxSize - 3.5 - padding)
  tieShape.lineTo(offsetX - radius, offsetY - radius)
  tieShape.lineTo(offsetX - radius, offsetY)
  tieShape.lineTo(boxSize / 3, boxSize - 2.5)
  tieShape.lineTo(-boxSize / 3, boxSize - 2.5)
  tieShape.lineTo(-offsetX + radius, offsetY)
  tieShape.lineTo(-offsetX + radius, offsetY - radius)
  tieShape.lineTo(-boxSize - padding, boxSize - 3.5 - padding)
  tieShape.lineTo(-boxSize - padding, -boxSize - 3.5 - padding)
  tieShape.lineTo(boxSize + padding, -boxSize - 3.5 - padding)

  extendedTieShape: tieShape
  tieDepth: 0.4

  railRadius: radius
  railDistance: offsetX - radius

  constructor: ->
    super

    @spineMaterial = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)
    @tieMaterial = @spineMaterial.clone()
    @railMaterial = @spineMaterial.clone()

    @materials = [@spineMaterial, @tieMaterial, @railMaterial]

