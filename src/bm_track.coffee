class LW.BMTrack extends LW.Track
  boxSize = 2
  offsetY = -3.5

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
  tieShape.lineTo(offsetX, offsetY)
  tieShape.lineTo(offsetX - radius, offsetY)
  tieShape.lineTo(boxSize / 2, boxSize - 3)
  tieShape.lineTo(-boxSize / 2, boxSize - 3)
  tieShape.lineTo(-offsetX + radius, offsetY)
  tieShape.lineTo(-offsetX, offsetY)
  tieShape.lineTo(-boxSize, boxSize - 3.5 - boxSize / 4)

  tieShape: tieShape
  tieDepth: 0.4

  railRadius: radius
  railDistance: offsetX - radius

  constructor: ->
    super

    @spineMaterial = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)
    @tieMaterial = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)
    @railMaterial = new THREE.MeshPhongMaterial(color: 0xff0000, ambient: 0x090909, specular: 0x333333, shininess: 30)
