class LW.Train extends THREE.Object3D
  constructor: (@track, options = {}) ->
    super()

    {
      @numberOfCars, @velocity
    } = options

    @cars = []

    @numberOfCars ?= 1
    @velocity = 15
    @displacement = 0

    if track?.carModel
      loader = new THREE.ColladaLoader
      loader.load "resources/models/#{track.carModel}", (result) =>
        @carProto = result.scene.children[0]
        @carProto.scale.copy(track.carScale)
        @carRot = new THREE.Matrix4().makeRotationFromEuler(track.carRotation, 'XYZ')

        for child in @carProto.children
          child.castShadow = true

        @rebuild()
    else
      geo = new THREE.CubeGeometry(8,8,16)
      mat = new THREE.MeshLambertMaterial(color: 0xeeeeee)
      @carProto = new THREE.Mesh(geo, mat)

      @rebuild()

  rebuild: ->
    @remove(@cars.pop()) while @cars.length

    if @numberOfCars
      for i in [1..@numberOfCars]
        car = @carProto.clone()

        if i == @numberOfCars
          car.remove(car.getObjectByName('connector'))

        @cars.push(car)
        @add(car)

    @currentTime = 0.0

  up = new THREE.Vector3(0, 1, 0)
  down = new THREE.Vector3(0, -1, 0)

  zero = new THREE.Vector3()
  mat = new THREE.Matrix4()

  simulate: (delta) ->
    return if !@numberOfCars or !(spline = @track.spline)

    if @lastTangent
      alpha = down.angleTo(@lastTangent)
      a = 9.81 * Math.cos(alpha)
      @velocity = @velocity + a * delta

    @displacement = @displacement + @velocity * delta

    if @position == 0
      @currentTime = 0
    else
      @currentTime = @displacement / spline.getLength()
    if @currentTime > 1
      @currentTime = 0
      @displacement = 0

    lastPos = spline.getPointAt(@currentTime)
    deltaPoint = @currentTime
    desiredDistance = @track.carDistance

    for car, i in @cars
      pos = null

      if i > 0
        while deltaPoint > 0
          pos = spline.getPointAt(deltaPoint)
          break if pos.distanceTo(lastPos) >= desiredDistance
          deltaPoint -= 0.001
          deltaPoint = 0 if deltaPoint < 0
      else
        pos = lastPos

      if pos
        lastPos = pos
        tangent = spline.getTangentAt(deltaPoint).normalize()
        @lastTangent = tangent if i == 0

        bank = THREE.Math.degToRad(spline.getBankAt(deltaPoint))
        binormal = up.clone().applyAxisAngle(tangent, bank)

        normal = tangent.clone().cross(binormal).normalize()
        binormal = normal.clone().cross(tangent).normalize()

        zero.set(0, 0, 0)
        mat.set(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

        car.position.copy(pos).add(zero.applyMatrix4(mat))
        car.rotation.setFromRotationMatrix(mat.multiply(@carRot))

        if LW.onRideCamera
          LW.renderer.camera.position.copy(pos).add(new THREE.Vector3(0, 3, 0).applyMatrix4(mat))
          LW.renderer.camera.rotation.setFromRotationMatrix(mat)

    return
