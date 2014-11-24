class LW.BMTrack extends LW.TrackMesh
  @heartlineOffset: new THREE.Vector3(0, -3.5, 0)

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

  frictionWheels = new THREE.BoxGeometry(3.8, 3.6, 6)
  material = new THREE.MeshPhongMaterial(specular: 0xaaaaaa)
  frictionWheels = new THREE.Mesh(frictionWheels, material)

  carDistance: 20
  onRideCameraOffset: new THREE.Vector3(2, 5, -5)

  @shapes {
    spine: {shape: boxShape, every: 8}
    tie: {shape: tieShape, on: 'spine', depth: 0.4}
    frictionWheels: {mesh: frictionWheels, on: 'tie', offset: new THREE.Vector3(0, -1.2, 4.5)}
  }

  @rails {
    left: {radius, distance: new THREE.Vector2(railDistance, 0)}
    right: {radius, distance: new THREE.Vector2(-railDistance, 0)}
  }

  enterSegment: (segment) ->
    super

    if !@shapes.spine.offset && "TransportSegment,BrakeSegment,StationSegment".indexOf(segment.type) != -1
      @shapes.spine.offset = new THREE.Vector2(0, -2)
      @shapes.tie.shape = lowbeamTieShape
      @shapes.tie.prepare()

      @shapes.frictionWheels.mesh.material.color = segment.colorObject('tieColor')
      @shapes.frictionWheels.disabled = false
      @shapes.frictionWheels.skipFirst = true

  leaveSegment: (segment) ->
    super

    if @shapes.spine.offset
      @shapes.spine.offset = null
      @shapes.tie.shape = tieShape
      @shapes.tie.prepare()

    @shapes.frictionWheels.disabled = true
