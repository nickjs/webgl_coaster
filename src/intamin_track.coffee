class LW.IntaminTrack extends LW.TrackMesh
  # class @TrackSegment extends LW.TrackMesh.TrackSegment
  #   step: ->

  railRadius: railRadius = 0.425
  railDistance: railDistance = 3.0

  numberOfRails: 3

  tieX = railDistance - 0.2
  tieHeight = railRadius - 0.1
  tieDepth: tieHeight * 2

  tieShape = new THREE.Shape
  tieShape.moveTo(tieX, tieHeight)
  tieShape.lineTo(-tieX, tieHeight)
  tieShape.lineTo(-tieX, -tieHeight)
  tieShape.lineTo(tieX, -tieHeight)
  tieShape: tieShape
  extendedTieShape: tieShape

  spineDivisionLength: 4
  liftX = 0.95
  liftY = 0.525
  liftHeight = 0.4
  liftShape = new THREE.Shape
  liftShape.moveTo(-liftX, liftY - liftHeight)
  liftShape.lineTo(liftX, liftY - liftHeight)
  liftShape.lineTo(liftX, liftY)
  liftShape.lineTo(-liftX, liftY)
  liftShape: liftShape

  liftTexture: "#{BASE_URL}/textures/cable.jpg"

  gearGeometry = new THREE.CylinderGeometry(6, 6, 1.85)
  gearGeometry.applyMatrix(new THREE.Matrix4().makeRotationZ(Math.PI / 2))
  gearGeometry: gearGeometry

  gearOffset: new THREE.Vector3(-1, 5.8, 0)

  carDistance: 20
  onRideCameraOffset: new THREE.Vector3(2, 5, -5)
