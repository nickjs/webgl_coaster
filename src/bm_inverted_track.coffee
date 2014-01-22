class LW.BMInvertedTrack extends LW.TrackMesh
  boxSize = 2
  offsetY = 3

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
  offsetY = radius * 0.75
  padding = boxSize / 4

  tieShape = new THREE.Shape
  tieShape.moveTo(-boxSize, -boxSize + 3 + padding)
  tieShape.lineTo(-offsetX + radius * 1.5, 0)
  tieShape.lineTo(-offsetX + radius * 1.5, -offsetY)
  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5)
  tieShape.lineTo(boxSize / 2, -boxSize + 2.5)
  tieShape.lineTo(offsetX - radius * 1.5, -offsetY)
  tieShape.lineTo(offsetX - radius * 1.5, 0)
  tieShape.lineTo(boxSize, -boxSize + 3 + padding)

  tieShape: tieShape

  tieShape = new THREE.Shape
  tieShape.moveTo(-boxSize - padding, -boxSize + 3 + padding)
  tieShape.lineTo(-offsetX + radius * 1.5, 0)
  tieShape.lineTo(-offsetX + radius * 1.5, -offsetY)
  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5)
  tieShape.lineTo(boxSize / 2, -boxSize + 2.5)
  tieShape.lineTo(offsetX - radius * 1.5, -offsetY)
  tieShape.lineTo(offsetX - radius * 1.5, 0)
  tieShape.lineTo(boxSize + padding, -boxSize + 3 + padding)
  tieShape.lineTo(boxSize + padding, boxSize + 3 + padding)
  tieShape.lineTo(-boxSize - padding, boxSize + 3 + padding)

  extendedTieShape: tieShape
  tieDepth: 0.4

  railRadius: radius
  railDistance: railDistance = offsetX - radius

  offsetY = -boxSize + 3 + padding

  wireframeSpine: [new THREE.Vector3(0, offsetY)]
  wireframeTies: [
    new THREE.Vector3(railDistance, 0)
    new THREE.Vector3(boxSize, offsetY)

    new THREE.Vector3(boxSize, offsetY) # line pieces
    new THREE.Vector3(-boxSize, offsetY)

    new THREE.Vector3(-boxSize, offsetY)
    new THREE.Vector3(-railDistance, 0)
  ]

  carModel: 'inverted.dae'
  carScale: new THREE.Vector3(0.0429, 0.0429, 0.037)
  carRotation: new THREE.Euler(-Math.PI * 0.5, 0, Math.PI, 'XYZ')
  carDistance: 9

  onRideCameraOffset: new THREE.Vector3(3.85, -7.3, -0.5)
