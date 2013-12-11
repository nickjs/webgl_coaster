class LW.Train extends THREE.Object3D
  constructor: (options) ->
    super()

    {
      @numberOfCars, @carGeometry, @carMaterial, @carSpacing, @carLength, @movementSpeed
    } = options

    @cars = []
    @rebuild()

    @movementSpeed ||= 0.08

  rebuild: ->
    @carGeometry ||= new THREE.CubeGeometry(8,8,16)
    @carMaterial ||= new THREE.MeshLambertMaterial(color: 0xeeeeee)
    @carSpacing ||= 2
    @carLength ||= 16

    @remove(@cars.pop()) while @cars.length

    if @numberOfCars
      for i in [0..@numberOfCars - 1]
        car = new THREE.Mesh(@carGeometry, @carMaterial)
        car.castShadow = true
        @cars.push(car)
        @add(car)

    @currentTime = 0.0

  attachToTrack: (@track) ->
    @spline = @track.spline

  up = new THREE.Vector3(0,1,0)

  simulate: (delta) ->
    return if !@numberOfCars or !@spline

    @currentTime += @movementSpeed * delta
    @currentTime = 0 if @currentTime > 1

    lastPos = @spline.getPointAt(@currentTime)
    for car, i in @cars
      pos = null
      desiredDistance = i * 18

      deltaPoint = @currentTime
      if desiredDistance > 0
        while deltaPoint > 0
          pos = @spline.getPointAt(deltaPoint)
          break if pos.distanceTo(lastPos) >= desiredDistance
          deltaPoint += 0.01
          deltaPoint = 0 if deltaPoint > 1
      else
        pos = lastPos

      if pos
        tangent = @spline.getTangentAt(deltaPoint).normalize()

        bank = THREE.Math.degToRad(@spline.getBankAt(deltaPoint))
        binormal = up.clone().applyAxisAngle(tangent, bank)

        normal = tangent.clone().cross(binormal).normalize()
        binormal = normal.clone().cross(tangent).normalize()
        mat = new THREE.Matrix4(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

        car.position.copy(pos).add(new THREE.Vector3(0, 5, 0).applyMatrix4(mat))
        car.rotation.setFromRotationMatrix(mat)

        if LW.onRideCamera
          LW.renderer.camera.position.copy(pos).add(new THREE.Vector3(0, 3, 0).applyMatrix4(mat))
          LW.renderer.camera.rotation.setFromRotationMatrix(mat)

    return
