class LW.BMInvertedTrack extends LW.BMTrack
  boxSize = 2
  offsetY = 3

  boxShape = new THREE.Shape
  boxShape.moveTo(-boxSize, -boxSize + offsetY)
  boxShape.lineTo(-boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, boxSize + offsetY)
  boxShape.lineTo(boxSize, -boxSize + offsetY)

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

  extendedTieShape = new THREE.Shape
  extendedTieShape.moveTo(-boxSize - padding, -boxSize + 3 + padding)
  extendedTieShape.lineTo(-offsetX + radius * 1.5, 0)
  extendedTieShape.lineTo(-offsetX + radius * 1.5, -offsetY)
  extendedTieShape.lineTo(-boxSize / 2, -boxSize + 2.5)
  extendedTieShape.lineTo(boxSize / 2, -boxSize + 2.5)
  extendedTieShape.lineTo(offsetX - radius * 1.5, -offsetY)
  extendedTieShape.lineTo(offsetX - radius * 1.5, 0)
  extendedTieShape.lineTo(boxSize + padding, -boxSize + 3 + padding)
  extendedTieShape.lineTo(boxSize + padding, boxSize + 3 + padding)
  extendedTieShape.lineTo(-boxSize - padding, boxSize + 3 + padding)

  lowbeamTieShape = new THREE.Shape
  lowbeamTieShape.moveTo(-boxSize, -boxSize + 3 + padding)
  lowbeamTieShape.lineTo(-offsetX + radius * 1.5, 0)
  lowbeamTieShape.lineTo(-offsetX + radius * 1.5, -offsetY)
  lowbeamTieShape.lineTo(-boxSize / 2, -boxSize + 2.5)
  lowbeamTieShape.lineTo(boxSize / 2, -boxSize + 2.5)
  lowbeamTieShape.lineTo(offsetX - radius * 1.5, -offsetY)
  lowbeamTieShape.lineTo(offsetX - radius * 1.5, 0)
  lowbeamTieShape.lineTo(boxSize, -boxSize + 3 + padding)
  lowbeamTieShape.lineTo(boxSize, boxSize + 3)
  lowbeamTieShape.lineTo(-boxSize, boxSize + 3)

  carModel: 'inverted'
  carDistance: 8.9

  onRideCameraOffset: new THREE.Vector3(3.85, -7.3, -0.5)

  invertedOffset = -15

  supportOffset: new THREE.Vector3(0, 4, 0)

  @shapes {
    spine: {shape: boxShape}
    tie: {shape: tieShape}
    frictionWheels: {offset: new THREE.Vector3(0, 1.2, 4.5)}
    catwalkStepsLeft: {offset: new THREE.Vector3(-8.5, invertedOffset - 1)}
    catwalkStepsRight: {offset: new THREE.Vector3(8.5, invertedOffset - 1)}
    catwalkLeft: {offset: new THREE.Vector2(-8.5, invertedOffset)}
    catwalkRight: {offset: new THREE.Vector2(8.5, invertedOffset)}
    catwalkRailingLeft: {offset: new THREE.Vector2(-13.5, invertedOffset)}
    catwalkRailingRight: {offset: new THREE.Vector2(13.5, invertedOffset)}
    catwalkCenter: {offset: new THREE.Vector2(0, invertedOffset), enabled: true}
    station: {offset: new THREE.Vector2(0, invertedOffset)}
  }

  enterSegment: (segment) ->
    hasOffset = !!@shapes.spine.offset
    super

    if !hasOffset && @shapes.spine.offset
      @shapes.spine.offset.negate()
      @shapes.tie.shape = lowbeamTieShape
      @shapes.tie.prepare()

  leaveSegment: (segment) ->
    hasOffset = !!@shapes.spine.offset
    super

    if hasOffset && !@shapes.spine.offset
      @shapes.tie.shape = tieShape
      @shapes.tie.prepare()
