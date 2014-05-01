class LW.BMTrack extends LW.TrackMesh
  boxSize = 2
  offsetY = -3

  boxShape = new THREE.Shape
  boxShape.moveTo(-boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, -boxSize + offsetY)

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

  extendedTieShape = new THREE.Shape
  extendedTieShape.moveTo(boxSize + padding, boxSize - 3 - padding)
  extendedTieShape.lineTo(offsetX - radius * 1.5, offsetY)
  extendedTieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75)
  extendedTieShape.lineTo(boxSize / 2, boxSize - 2.5)
  extendedTieShape.lineTo(-boxSize / 2, boxSize - 2.5)
  extendedTieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75)
  extendedTieShape.lineTo(-offsetX + radius * 1.5, offsetY)
  extendedTieShape.lineTo(-boxSize - padding, boxSize - 3 - padding)
  extendedTieShape.lineTo(-boxSize - padding, -boxSize - 3 - padding)
  extendedTieShape.lineTo(boxSize + padding, -boxSize - 3 - padding)

  lowbeamTieShape = new THREE.Shape
  lowbeamTieShape.moveTo(boxSize, boxSize - 3 - padding)
  lowbeamTieShape.lineTo(offsetX - radius * 1.5, offsetY)
  lowbeamTieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75)
  lowbeamTieShape.lineTo(boxSize / 2, boxSize - 2.5)
  lowbeamTieShape.lineTo(-boxSize / 2, boxSize - 2.5)
  lowbeamTieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75)
  lowbeamTieShape.lineTo(-offsetX + radius * 1.5, offsetY)
  lowbeamTieShape.lineTo(-boxSize, boxSize - 3 - padding)
  lowbeamTieShape.lineTo(-boxSize, boxSize - 5)
  lowbeamTieShape.lineTo(boxSize, boxSize - 5)

  railDistance = offsetX - radius
  offsetY = boxSize - 3 - padding

  liftShape = new THREE.Shape
  liftShape.moveTo(-0.7, -0.3)
  liftShape.lineTo(-0.7, 0.3)
  liftShape.lineTo(0.7, 0.3)
  liftShape.lineTo(0.7, -0.3)

  gearGeometry = new THREE.CylinderGeometry(3, 3, 1.35)
  gearGeometry.applyMatrix(new THREE.Matrix4().makeRotationZ(Math.PI / 2))
  gearGeometry: gearGeometry

  gearOffset: new THREE.Vector3(-0.7, 2.25, 0)

  wireframeSpine: [new THREE.Vector3(0, offsetY)]
  wireframeTies: [
    new THREE.Vector3(railDistance, 0)
    new THREE.Vector3(boxSize, offsetY)

    new THREE.Vector3(boxSize, offsetY) # line pieces
    new THREE.Vector3(-boxSize, offsetY)

    new THREE.Vector3(-boxSize, offsetY)
    new THREE.Vector3(-railDistance, 0)
  ]

  carDistance: 20
  onRideCameraOffset: new THREE.Vector3(2, 5, -5)

  shapes: {
    spine: {shape: boxShape, every: 7}
    tie: {shape: tieShape, every: 7, depth: 0.4}
    lowbeamTie: {shape: lowbeamTieShape, every: 8, depth: 0.4, disabled: true}
    lift: {shape: liftShape, segment: 'LiftSegment'}
  }

  rails: [
    {radius, distance: new THREE.Vector2(railDistance, 0)}
    {radius, distance: new THREE.Vector2(-railDistance, 0)}
  ]

  prepareMaterials: ->
    super

    liftTexture = LW.textures.liftChain
    liftTexture.wrapT = THREE.RepeatWrapping
    liftTexture.offset.setX(0.5)

    @liftMaterial = new THREE.MeshLambertMaterial(map: liftTexture)

    @stationMaterial = new THREE.MeshLambertMaterial(color: 0xcccccc)

    station = new THREE.Shape
    station.moveTo(-35, -50)
    station.lineTo(-35, 0)
    station.lineTo(-6, 0)
    station.lineTo(-6, -8)
    station.lineTo(6, -8)
    station.lineTo(6, 0)
    station.lineTo(35, 0)
    station.lineTo(35, -50)
    @shapes.station = {shape: station, segment: 'StationSegment'}

  enterSegment: (segment) ->
    if "TransportSegment,BrakeSegment,StationSegment".indexOf(segment.type) != -1
      @shapes.spine.offset = new THREE.Vector2(0, -2)
      @shapes.lowbeamTie.disabled = false
      @shapes.tie.disabled = true

  leaveSegment: (segment) ->
    @shapes.spine.offset = null
    @shapes.tie.disabled = false
    @shapes.lowbeamTie.disabled = true
