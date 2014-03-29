class LW.Train extends THREE.Object3D
  velocity: 20
  initialVelocity: 20
  displacement: 0

  numberOfCars: 1

  constructor: (@track, options) ->
    super()

    LW.mixin(this, options)

    if track?.carModel
      loader = new THREE.ColladaLoader
      loader.load "resources/models/#{track.carModel}", (result) =>
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
      geo = new THREE.CubeGeometry(8,8,16)
      mat = new THREE.MeshLambertMaterial(color: 0xeeeeee)
      @carProto = new THREE.Mesh(geo, mat)

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

  start: ->
    @shouldSimulate = true
    @velocity = @initialVelocity
    @displacement = 0
    @rebuild()

  stop: ->
    @shouldSimulate = false
    @clear()
    @cars = []

  down = new THREE.Vector3(0, -1, 0)
  mat = new THREE.Matrix4()

  simulate: (delta) ->
    return if !@shouldSimulate or !@cars.length or !(model = @track.model)

    separator = model.findSeparatorFromT(@currentTime)
    if separator.type == LW.Separator.TYPE.LIFT
      @velocity = Math.max(@velocity, separator.settings.lift_speed * 10)

      # chain animation
      LW.track.liftMaterial.map.offset.y -= 0.4
      for gear in LW.track.gears
        gear.rotation.x -= 0.1

    if @lastTangent
      alpha = down.angleTo(@lastTangent)
      a = 29.43 * Math.cos(alpha)
      @velocity = @velocity + a * delta

    @displacement = @displacement + @velocity * delta

    if @displacement <= 0
      @currentTime = 0
    else
      @currentTime = @displacement / model.spline.getLength()
    if @currentTime > 1
      @currentTime = 0
      @displacement = 0

    lastPos = model.spline.getPointAt(@currentTime)
    deltaPoint = @currentTime
    desiredDistance = @track.carDistance

    for car, i in @cars
      pos = null

      if i > 0
        while deltaPoint > 0
          pos = model.spline.getPointAt(deltaPoint)
          break if pos.distanceTo(lastPos) >= desiredDistance
          deltaPoint -= 0.001
          deltaPoint = 0 if deltaPoint < 0
      else
        pos = lastPos


      if pos
        tangent = LW.positionObjectOnSpline(car, model.spline, deltaPoint, null, @carRot)
        lastPos = pos

        if i == 0
          @lastTangent = tangent

          if model.onRideCamera || @cameraHelper.visible
            LW.positionObjectOnSpline(@camera, model.spline, deltaPoint, @track.onRideCameraOffset)

    return
