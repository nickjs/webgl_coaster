class LW.Train extends THREE.Object3D
  velocity: 0
  initialVelocity: 0
  displacement: 0
  acceleration: 0
  initialAcceleration: -0.01

  numberOfCars: 1

  constructor: (@track, options) ->
    super()

    LW.mixin(this, options)

    @sound = new Sound(LW.renderer.audioContext)
    @sound.load(LW.sounds.coaster)
    @sound.setVolume(1)
    @sound.setLoop(true)

    @chainSound = new Sound(LW.renderer.audioContext)
    @chainSound.load(LW.sounds.chain)
    @chainSound.setVolume(0.3)
    @chainSound.setPlayBackRate(1.6)
    @chainSound.setLoop(true)

    if track?.carModel
      loader = new THREE.ColladaLoader
      loader.load "#{BASE_URL}/models/#{track.carModel}", (result) =>
        @carProto = result.scene.children[0]
        @carProto.scale.copy(track.carScale)
        @carRot = new THREE.Matrix4().makeRotationFromEuler(track.carRotation, 'XYZ')

        sizeVector = new THREE.Vector3
        @carProto.traverse (child) ->
          if child instanceof THREE.Mesh
            child.geometry.computeBoundingBox()
            if child.geometry.boundingBox.size(sizeVector).lengthSq() > 10000
              child.castShadow = true

        @rebuild()
    else
      geo = new THREE.BoxGeometry(8,8,16)
      mat = new THREE.MeshLambertMaterial(color: 0xeeeeee)
      @carProto = new THREE.Mesh(geo, mat)
      @carProto.castShadow = true

      @rebuild()

    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000)
    @cameraHelper = new THREE.CameraHelper(@camera)
    @cameraHelper.visible = false

  rebuild: ->
    @clear()
    @cars = []

    if @numberOfCars && @carProto
      for i in [1..@numberOfCars]
        car = @carProto.clone()

        if i == @numberOfCars
          car.remove(car.getObjectByName('connector'))

        @cars.push(car)
        @add(car)

    @add(@cameraHelper)
    @add(@camera)

    # oldShouldSimulate = false
    # @shouldSimulate = true
    # @update(0)
    # @shouldSimulate = oldShouldSimulate

  start: ->
    return unless @model = LW.model

    @shouldSimulate = true
    @acceleration = @initialAcceleration
    @velocity = @initialVelocity

    for separator, i in @model.separators
      if separator.type == LW.Separator.TYPE.STATION
        @separator = separator
        @nextSeparator = @model.separators[i + 1]
        break

    totalLength = @model.spline.getLength()
    distance = if @nextSeparator
      @nextSeparator.position * totalLength - @separator.position * totalLength
    else
      totalLength - @separator.position * totalLength

    @displacement = distance / 2 + @separator.position * totalLength

    @sound.play()

  stop: ->
    @shouldSimulate = false
    @clear()
    @cars = []

    @sound.stop()

  down = new THREE.Vector3(0, -1, 0)
  mat = new THREE.Matrix4()

  update: (delta) ->
    return if !@shouldSimulate or !@cars?.length or !(model = @model)

    if @nextSeparator && @currentTime >= @nextSeparator.position
      @leaveSegment?(@separator, @nextSeparator)
      @separator = @nextSeparator
      @nextSeparator = model.separators[model.separators.indexOf(@nextSeparator) + 1]
      @enterSegment?(@separator, @nextSeparator)

    switch @separator.type
      when LW.Separator.TYPE.LIFT
        @velocity = Math.max(@velocity, @separator.settings.lift_speed * 10)

        # chain animation
        LW.track.liftMaterial.map.offset.y -= @separator.settings.lift_speed - 0.01
        # for gear in LW.track.gears
        #   gear.rotation.x -= 0.1

      when LW.Separator.TYPE.BRAKE
        if @separator.decelApplied
          if @velocity <= @separator.settings.speed_limit * 10
            @acceleration += @separator.settings.decel * 10
            @separator.decelApplied = false
        else if @velocity > @separator.settings.speed_limit * 10
          @acceleration -= @separator.settings.decel * 10
          @separator.decelApplied = true

      when LW.Separator.TYPE.TRANSPORT, LW.Separator.TYPE.STATION
        if @separator.accelApplied
          if @velocity > @separator.settings.transportSpeed * 10
            @acceleration -= @separator.settings.transportAccel * 10
            @separator.accelApplied = false
        else if @velocity <= @separator.settings.transportSpeed * 10
          @acceleration += @separator.settings.transportAccel * 10
          @separator.accelApplied = true

        if @separator.type == LW.Separator.TYPE.STATION
          if !@startHoldTime
            @startHoldTime = new Date()
          else
            @holdHere = new Date() - @startHoldTime < 2000

    if @lastTangent && !@holdHere
      alpha = down.angleTo(@lastTangent)
      a = 29.43 * Math.cos(alpha) + @acceleration
      @velocity = @velocity + a * delta

    @displacement = @displacement + @velocity * delta unless @holdHere

    @sound.setPlayBackRate(if @holdHere then 0.0000001 else @velocity * 0.01 + 0.3)
    @chainSound[if @separator.type == LW.Separator.TYPE.LIFT then "play" else "stop"]()

    totalLength = model.spline.getLength()
    if @displacement <= 0 || @displacement >= totalLength
      @currentTime = 0
      @displacement = 0
      @separator = model.separators[0]
      @nextSeparator = model.separators[1]
    else
      @currentTime = @displacement / totalLength

    lastPos = model.spline.getPointAt(@currentTime)
    deltaPoint = @currentTime
    desiredDistance = @track.carDistance * @track.carDistance

    for car, i in @cars
      pos = null

      if i > 0
        while deltaPoint >= 0
          pos = model.spline.getPointAt(deltaPoint)
          break if pos.distanceToSquared(lastPos) >= desiredDistance
          deltaPoint -= 0.001
          deltaPoint = 1 + deltaPoint if deltaPoint < 0
      else
        pos = lastPos

      if pos
        tangent = LW.positionObjectOnSpline(car, model.spline, deltaPoint, null, @carRot)
        lastPos = pos

        if i == 0
          @lastTangent = tangent

          if model.onRideCamera || @cameraHelper?.visible
            LW.positionObjectOnSpline(@camera, model.spline, deltaPoint, @track.onRideCameraOffset)

    return

  leaveSegment: (segment) ->
    if segment.accelApplied
      @acceleration -= segment.settings.transportAccel * 10
      segment.accelApplied = false
    if segment.decelApplied
      @acceleration += segment.settings.decel * 10
      segment.decelApplied = false

    if @startHoldTime
      @startHoldTime = null
