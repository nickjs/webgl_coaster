class LW.Controls
  enabled: true
  moveSpeed: 80
  lookSpeed: 0.01

  constructor: (@cameras, @domElement) ->
    @pitchObject = new THREE.Object3D
    @pitchObject.add(@cameras[@cameras.length - 1])

    @yawObject = new THREE.Object3D
    @yawObject.add(@pitchObject)

    LW.renderer.scene.add(@yawObject)

    document.addEventListener('pointerlockchange', @onPointerLockChange, false)
    document.addEventListener('mozpointerlockchange', @onPointerLockChange, false)
    document.addEventListener('webkitpointerlockchange', @onPointerLockChange, false)

    @onPointerLockChange()

    document.addEventListener('mousemove', @onMouseMove, false)
    document.addEventListener('keydown', @onKeyDown, false)
    document.addEventListener('keyup', @onKeyUp, false)

  pickCamera: (e) ->
    if LW.renderer.useQuadView
      camIndex = 0
      camIndex += 1 if e.clientX > window.innerWidth / 2
      camIndex += 2 if e.clientY > window.innerHeight / 2
    else
      camIndex = 3

    @camera = @cameras[camIndex]

  HALF_PI = Math.PI / 2

  onMouseMove: (e) =>
    return if !@enabled

    x = e.movementX || e.mozMovementX || e.webkitMovementX || 0
    y = e.movementY || e.mozMovementY || e.webkitMovementY || 0

    @yawObject.rotation.y -= x * @lookSpeed
    @pitchObject.rotation.x -= y * @lookSpeed

    @pitchObject.rotation.x = Math.max(-HALF_PI, Math.min(HALF_PI, @pitchObject.rotation.x))

  onKeyDown: (e) =>
    switch e.keyCode
      when 38, 87 then @moveForward = true
      when 37, 65 then @moveLeft = true
      when 40, 83 then @moveBackward = true
      when 39, 68 then @moveRight = true
      when 81 then @moveUp = true
      when 69 then @moveDown = true
      when 16 then @moveSpeed *= 2

  onKeyUp: (e) =>
    switch e.keyCode
      when 38, 87 then @moveForward = false
      when 37, 65 then @moveLeft = false
      when 40, 83 then @moveBackward = false
      when 39, 68 then @moveRight = false
      when 81 then @moveUp = false
      when 69 then @moveDown = false
      when 16 then @moveSpeed *= 0.5

  onClick: (e) =>
    @domElement.requestPointerLock ||= @domElement.requestPointerLock || @domElement.mozRequestPointerLock || @domElement.webkitRequestPointerLock
    @domElement.requestPointerLock()

  onPointerLockChange: (e) =>
    @enabled = document.pointerLockElement == @domElement || document.mozPointerLockElement == @domElement || document.webkitPointerLockElement == @domElement
    if @enabled
      document.removeEventListener('click', @onClick)
    else
      document.addEventListener('click', @onClick)

  update: (delta) ->
    return if !@enabled

    x = -@moveSpeed * delta if @moveLeft
    x = @moveSpeed * delta if @moveRight
    y = @moveSpeed * delta if @moveUp
    y = -@moveSpeed * delta if @moveDown
    z = -@moveSpeed * delta if @moveForward
    z = @moveSpeed * delta if @moveBackward

    @yawObject.translateX(x) if x
    @yawObject.translateY(y) if y
    @yawObject.translateZ(z) if z
