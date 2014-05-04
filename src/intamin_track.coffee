class LW.IntaminTrack extends LW.TrackMesh
  radius = 0.425
  railDistance = 3.0
  dropRailDistance = railDistance * 1.9

  @rails {
    left: {radius, distance: new THREE.Vector2(railDistance, 0)}
    right: {radius, distance: new THREE.Vector2(-railDistance, 0)}
    third: {radius, disabled: true, distance: new THREE.Vector2(0, -dropRailDistance)}
    fourthLeft: {radius, disabled: true, distance: new THREE.Vector2(railDistance, -dropRailDistance)}
    fourthRight: {radius, disabled: true, distance: new THREE.Vector2(-railDistance, -dropRailDistance)}
  }

  tieX = railDistance - 0.2
  tieHeight = radius - 0.1

  tieShape = new THREE.Shape
  tieShape.moveTo(tieX, tieHeight)
  tieShape.lineTo(-tieX, tieHeight)
  tieShape.lineTo(-tieX, -tieHeight)
  tieShape.lineTo(tieX, -tieHeight)

  threeTie = new THREE.Shape
  threeTie.moveTo(railDistance - tieHeight, -tieHeight)
  threeTie.lineTo(0, -dropRailDistance + tieHeight)
  threeTie.lineTo(-railDistance + tieHeight, -tieHeight)
  threeTie.lineTo(-railDistance - tieHeight, -tieHeight)
  threeTie.lineTo(0, -dropRailDistance - tieHeight)
  threeTie.lineTo(railDistance + tieHeight, -tieHeight)

  fourTie = new THREE.Shape
  fourTie.moveTo(railDistance - tieHeight, -tieHeight)
  fourTie.lineTo(railDistance - tieHeight, -dropRailDistance + tieHeight)
  fourTie.lineTo(-railDistance + tieHeight, -dropRailDistance + tieHeight)
  fourTie.lineTo(-railDistance + tieHeight, -tieHeight)
  fourTie.lineTo(-railDistance - tieHeight, -tieHeight)
  fourTie.lineTo(-railDistance - tieHeight, -dropRailDistance - tieHeight)
  fourTie.lineTo(railDistance + tieHeight, -dropRailDistance - tieHeight)
  fourTie.lineTo(railDistance + tieHeight, -tieHeight)


  # liftX = 0.95
  # liftY = 0.525
  # liftHeight = 0.4
  # liftShape = new THREE.Shape
  # liftShape.moveTo(-liftX, liftY - liftHeight)
  # liftShape.lineTo(liftX, liftY - liftHeight)
  # liftShape.lineTo(liftX, liftY)
  # liftShape.lineTo(-liftX, liftY)
  # liftShape: liftShape

  # liftTexture: "#{BASE_URL}/textures/cable.jpg"

  # gearGeometry = new THREE.CylinderGeometry(6, 6, 1.85)
  # gearGeometry.applyMatrix(new THREE.Matrix4().makeRotationZ(Math.PI / 2))
  # gearGeometry: gearGeometry

  # gearOffset: new THREE.Vector3(-1, 5.8, 0)

  @shapes {
    tie: {shape: tieShape, every: 6, depth: tieHeight * 2}
    threeTie: {shape: threeTie, on: 'tie', depth: tieHeight * 2, materialKey: 'tie'}
    fourTie: {shape: fourTie, on: 'tie', depth: tieHeight * 2, materialKey: 'tie'}
  }

  carDistance: 20
  onRideCameraOffset: new THREE.Vector3(2, 5, -5)

  prepareMaterials: ->
    super

    liftTexture = LW.textures.liftCable
    liftTexture.wrapT = THREE.RepeatWrapping
    @liftMaterial.map = liftTexture

  enterSegment: (segment) ->
    super

    @rails.third.disabled = segment.settings.flags != 32
    @rails.fourthLeft.disabled = @rails.fourthRight.disabled = segment.settings.flags != 36

    @shapes.threeTie.disabled = segment.settings.flags != 32
    @shapes.fourTie.disabled = segment.settings.flags != 36
