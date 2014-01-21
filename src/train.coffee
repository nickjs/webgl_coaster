class LW.Train extends THREE.Object3D
  constructor: (@track, options = {}) ->
    super()

    {
      @numberOfCars, @movementSpeed
    } = options

    @cars = []

    @numberOfCars ?= 1
    @movementSpeed ?= 0.06

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
        car.castShadow = true
        @cars.push(car)
        @add(car)

    @currentTime = 0.0

  up = new THREE.Vector3(0,1,0)
  zero = new THREE.Vector3()
  mat = new THREE.Matrix4()

  simulate: (delta) ->
    return if !@numberOfCars or !(spline = @track.spline)

    @currentTime += @movementSpeed * delta
    @currentTime = 0 if @currentTime > 1

    lastPos = spline.getPointAt(@currentTime)
    deltaPoint = @currentTime
    desiredDistance = @track.carDistance

    for car, i in @cars
      pos = null

      if i > 0
        while deltaPoint > 0
          pos = spline.getPointAt(deltaPoint)
          break if pos.distanceTo(lastPos) >= desiredDistance
          deltaPoint -= 0.01
          deltaPoint = 0 if deltaPoint < 0
      else
        pos = lastPos

      if pos
        lastPos = pos
        tangent = spline.getTangentAt(deltaPoint).normalize()

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
