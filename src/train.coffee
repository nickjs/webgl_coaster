class LW.Train extends THREE.Object3D
  velocity: 0
  initialVelocity: 0
  displacement: 0
  acceleration: 0
  initialAcceleration: -0.01

  numberOfCars: 1

  constructor: (@coaster, @track, options) ->
    super()

    @numberOfCars = @coaster.carsPerTrain ? @numberOfCars

    LW.mixin(this, options)

    @coasterSound = new LW.Sound(url: LW.sounds.coaster, volume: 0.5, loop: true)
    @tunnelSound = new LW.Sound(url: LW.sounds.tunnel, volume: 0.7, loop: true)
    @chainSound = new LW.Sound(url: LW.sounds.chain, volume: 0.4, playbackRate: 1.1, loop: true)
    @brakeSound = new LW.Sound(url: LW.sounds.brake, volume: 0.9, playbackRate: 1.25)

    if model = LW.models[track?.mesh.carModel]
      @carProto = model
      @carProto.isModel = true
    else
      geo = new THREE.BoxGeometry(8,8,16)
      mat = new THREE.MeshLambertMaterial(color: 0xeeeeee)
      @carProto = new THREE.Mesh(geo, mat)
      @carProto.castShadow = true

    @rebuild()

  rebuild: ->
    @clear()
    @cars = []

    if @numberOfCars && @carProto
      for i in [1..@numberOfCars]
        if @carProto.isModel
          car = new LW.Model @carProto, (geometry) ->
            sizeVector = new THREE.Vector3
            geometry.traverse (child) ->
              if child instanceof THREE.Mesh
                child.geometry.computeBoundingBox()
                if child.geometry.boundingBox.size(sizeVector).lengthSq() > 10000
                  child.castShadow = true

        else
          car = @carProto.clone()

        if i == @numberOfCars
          car.remove(car.getObjectByName('connector'))

        @cars.push(car)
        @add(car)

    return

  start: ->
    return unless @track

    @shouldSimulate = true
    @acceleration = @initialAcceleration
    @velocity = @initialVelocity

    for separator, i in @track.separators
      if separator.type == LW.Separator.TYPE.STATION
        @separator = separator
        @nextSeparator = @track.separators[i + 1]
        break

    totalLength = @track.spline.getLength()
    distance = if @nextSeparator
      @nextSeparator.position * totalLength - @separator.position * totalLength
    else
      totalLength - @separator.position * totalLength

    @displacement = distance / 2 + @separator.position * totalLength

    if @cars?[0]
      # @sound.position = @cars[0].position
      @sound = @coasterSound
      @sound.start()

  stop: ->
    @shouldSimulate = false
    @clear()
    @cars = []

    @sound.stop()

  down = new THREE.Vector3(0, -1, 0)
  mat = new THREE.Matrix4()

  showAnnotation: (annotation) ->
    return if annotation == @annotation

    if @annotation?.timer
      clearTimeout(@annotation.timer)
      document.body.removeChild(@annotation.div)

    @annotation = annotation

    div = document.createElement('div')
    div.innerHTML = "<a href='/users/#{annotation.user_info.id}'><img src='#{annotation.user_info.avatar}'>#{annotation.user_info.name}</a>: #{annotation.body}"
    div.className = 'lw-annotation'
    @annotation.div = div
    document.body.appendChild(div)

    @annotation.timer = setTimeout ->
      document.body.removeChild(div)
    , Math.max(annotation.body.length * 100, 2000)

  update: (delta) ->
    return if !@shouldSimulate or !@cars?.length or !(track = @track)

    if @nextSeparator && @currentTime >= @nextSeparator.position
      @leaveSegment(@separator, @nextSeparator)
      @separator = @nextSeparator
      @nextSeparator = track.separators[track.separators.indexOf(@nextSeparator) + 1]
      @enterSegment(@separator, @nextSeparator)

    index = if @annotation
      LW.annotations.indexOf(@annotation)
    else
      -1

    nextAnnotation = LW.annotations?[index + 1]
    if nextAnnotation?.time? && @currentTime >= nextAnnotation.time
      @showAnnotation(nextAnnotation)

    liftSpeed = if @separator.type == LW.Separator.TYPE.LIFT
      @separator.settings.lift_speed
    else
      0.05

    track.mesh.liftMaterial.map.offset.y -= liftSpeed

    switch @separator.type
      when LW.Separator.TYPE.LIFT
        @velocity = Math.max(@velocity, @separator.settings.lift_speed * 10)

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
            @enterSegment(@separator, @nextSeparator) if !@holdHere

    if @lastTangent && !@holdHere
      alpha = down.angleTo(@lastTangent)
      a = 29.43 * Math.cos(alpha) + @acceleration
      @velocity = @velocity + a * delta

    @displacement = @displacement + @velocity * delta unless @holdHere

    totalLength = track.spline.getLength()
    if @displacement <= 0 || @displacement >= totalLength
      @currentTime = 0
      @displacement = 0
      @separator = track.separators[0]
      @nextSeparator = track.separators[1]
    else
      @currentTime = @displacement / totalLength

    lastPos = track.spline.getPoint(@currentTime)
    deltaPoint = @currentTime
    deltaStep = 0.1 / totalLength
    desiredDistance = track.mesh.carDistance * track.mesh.carDistance

    for car, i in @cars
      pos = null

      if i > 0
        while deltaPoint >= 0
          pos = track.spline.getPoint(deltaPoint)
          break if pos.distanceToSquared(lastPos) >= desiredDistance
          deltaPoint -= deltaStep
          deltaPoint = 1 + deltaPoint if deltaPoint < 0
      else
        pos = lastPos

      if pos
        tangent = LW.positionObjectOnSpline(car, track.spline, deltaPoint)
        lastPos = pos

        if i == 0
          @lastTangent = tangent

          if @coaster.onRideCamera
            camera = LW.controls.container
            LW.positionObjectOnSpline(camera, track.spline, deltaPoint, track.mesh.onRideCameraOffset)
            camera.position.x += Math.random() * @velocity * 0.00015
            camera.position.y += Math.random() * @velocity * 0.0002

    @sound.update(playbackRate: if @holdHere then 0.0000001 else @velocity * 0.01 + 0.3)

    return

  enterSegment: (segment) ->
    return if segment.entered
    segment.entered = true

    @chainSound.start() if segment.type == LW.Separator.TYPE.LIFT
    @brakeSound.start() if segment.type in [LW.Separator.TYPE.BRAKE, LW.Separator.TYPE.TRANSPORT, LW.Separator.TYPE.STATION]

    if segment.settings.use_tunnel && @sound != @tunnelSound
      @sound.stop()
      @sound = @tunnelSound
      @sound.start()

  leaveSegment: (segment, nextSegment) ->
    segment.entered = false

    @chainSound.stop() if nextSegment.type != LW.Separator.TYPE.LIFT
    @brakeSound.stop() unless nextSegment.type in [LW.Separator.TYPE.BRAKE, LW.Separator.TYPE.TRANSPORT, LW.Separator.TYPE.STATION]

    if !segment.settings.use_tunnel && !nextSegment.settings.use_tunnel && @sound == @tunnelSound
      @sound.stop()
      @sound = @coasterSound
      @sound.start()

    if segment.accelApplied
      @acceleration -= segment.settings.transportAccel * 10
      segment.accelApplied = false
    if segment.decelApplied
      @acceleration += segment.settings.decel * 10
      segment.decelApplied = false

    if @startHoldTime
      @startHoldTime = null
