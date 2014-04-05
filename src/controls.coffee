class LW.Controls
  enabled: true
  moveSpeed: 80
  lookSpeed: 0.01

  constructor: (@cameras, @domElement) ->
    @camera = @cameras[@cameras.length - 1]

    @pitchObject = new THREE.Object3D
    @pitchObject.add(@camera)
    # LW.renderer.scene.add(@camera)

    @yawObject = new THREE.Object3D
    @yawObject.add(@pitchObject)

    LW.renderer.scene.add(@yawObject)

    @domElement.requestPointerLock ||= @domElement.requestPointerLock || @domElement.mozRequestPointerLock || @domElement.webkitRequestPointerLock
    document.exitPointerLock ||= document.exitPointerLock || document.mozExitPointerLock || document.webkitExitPointerLock

    document.addEventListener('pointerlockchange', @onPointerLockChange, false)
    document.addEventListener('mozpointerlockchange', @onPointerLockChange, false)
    document.addEventListener('webkitpointerlockchange', @onPointerLockChange, false)

    @onPointerLockChange()

    document.addEventListener('mousemove', @onMouseMove, false)
    document.addEventListener('keydown', @onKeyDown, false)
    document.addEventListener('keyup', @onKeyUp, false)

    if @domElement.requestPointerLock
      @domElement.addEventListener('click', @onClick)
      @domElement.addEventListener('contextmenu', @onClick)

    @domElement.addEventListener('mousedown', @mouseDownFallback)
    @domElement.addEventListener('mouseup', @mouseUpFallback)

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
    if @lastMouse
      x = e.screenX - @lastMouse.x
      y = e.screenY - @lastMouse.y
      @lastMouse.set(e.screenX, e.screenY)
    else if @enabled
      x = e.movementX || e.mozMovementX || e.webkitMovementX || 0
      y = e.movementY || e.mozMovementY || e.webkitMovementY || 0

    if x || y
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
    if !@lastMouse
      if @enabled
        document.exitPointerLock()
      else
        @domElement.requestPointerLock()

    e.preventDefault()

  onPointerLockChange: (e) =>
    @enabled = document.pointerLockElement == @domElement || document.mozPointerLockElement == @domElement || document.webkitPointerLockElement == @domElement

  mouseDownFallback: (e) =>
    @lastMouse = new THREE.Vector2(e.screenX, e.screenY)
    @mouseDownEvent = @lastMouse.clone()

  mouseUpFallback: (e) =>
    if e.screenX - @mouseDownEvent.x > 10 || e.screenY - @mouseDownEvent.y > 10
      setTimeout => @lastMouse = null # prevents pointerlock
    else
      @lastMouse = null

  update: (delta) ->
    x = -@moveSpeed * delta if @moveLeft
    x = @moveSpeed * delta if @moveRight
    y = @moveSpeed * delta if @moveUp
    y = -@moveSpeed * delta if @moveDown
    z = -@moveSpeed * delta if @moveForward
    z = @moveSpeed * delta if @moveBackward

    @yawObject.translateX(x) if x
    @yawObject.translateY(y) if y
    @yawObject.translateZ(z) if z

    # @camera.position.copy(@yawObject.position)
    # @camera.rotation.x = @pitchObject.rotation.x
    # @camera.rotation.y = @yawObject.rotation.y
