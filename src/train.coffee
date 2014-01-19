class LW.Train extends THREE.Object3D
  constructor: (@track, options = {}) ->
    super()

    {
      @numberOfCars, @movementSpeed
    } = options

    @cars = []

    @numberOfCars ?= 1
    @movementSpeed ?= 0.02

    if track?.carModel
      loader = new THREE.ColladaLoader
      loader.load "resources/models/#{track.carModel}", (result) =>
        @carProto = result.scene.children[0]
        for child in @carProto.children
          child.castShadow = true
        # car.rotateOnAxis(new THREE.Vector3(1,0,0), Math.PI * -0.5)
        # car.rotateOnAxis(new THREE.Vector3(0,0,1), Math.PI * 0.5)
        @carProto.scale.copy(track.carScale)
        @carProto.rotation.copy(track.carBaseRotation)

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

  simulate: (delta) ->
    return if !@numberOfCars or !(spline = @track.spline)

    @currentTime += @movementSpeed * delta
    @currentTime = 0 if @currentTime > 1

    lastPos = spline.getPointAt(@currentTime)
    for car, i in @cars
      pos = null
      desiredDistance = i * 18

      deltaPoint = @currentTime
      if desiredDistance > 0
        while deltaPoint > 0
          pos = spline.getPointAt(deltaPoint)
          break if pos.distanceTo(lastPos) >= desiredDistance
          deltaPoint += 0.01
          deltaPoint = 0 if deltaPoint > 1
      else
        pos = lastPos

      if pos
        tangent = spline.getTangentAt(deltaPoint).normalize()

        bank = THREE.Math.degToRad(spline.getBankAt(deltaPoint))
        binormal = up.clone().applyAxisAngle(tangent, bank)

        normal = tangent.clone().cross(binormal).normalize()
        binormal = normal.clone().cross(tangent).normalize()
        mat = new THREE.Matrix4(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

        car.position.copy(pos).add(@track.carOffset.clone().applyMatrix4(mat))
        # car.rotation.setFromRotationMatrix(mat)

        if LW.onRideCamera
          LW.renderer.camera.position.copy(pos).add(new THREE.Vector3(0, 3, 0).applyMatrix4(mat))
          LW.renderer.camera.rotation.setFromRotationMatrix(mat)

    return
