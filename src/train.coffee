class LW.Train extends THREE.Object3D
  constructor: (options) ->
    super()

    {
      @numberOfCars, @carGeometry, @carMaterial, @carSpacing
    } = options

    @cars = []

    @carGeometry ||= new THREE.CubeGeometry(8,8,16)
    @carMaterial ||= new THREE.MeshLambertMaterial(color: 0xeeeeee)
    @carSpacing ||= 2

    @currentTime = 0.0
    @movementSpeed = 0.08

    for i in [0..@numberOfCars - 1]
      car = new THREE.Mesh(@carGeometry, @carMaterial)
      @cars.push(car)
      @add(car)

  attachToTrack: (@track) ->
    @spline = @track.spline

  up = new THREE.Vector3(0,1,0)

  simulate: (delta) ->
    @currentTime += @movementSpeed * delta
    @currentTime = 0 if @currentTime > 1

    tangent = @spline.getTangentAt(@currentTime).normalize()

    bank = THREE.Math.degToRad(@spline.getBankAt(@currentTime))
    binormal = up.clone().applyAxisAngle(tangent, bank)

    normal = tangent.clone().cross(binormal).normalize()
    binormal = normal.clone().cross(tangent).normalize()
    mat = new THREE.Matrix4(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

    pos = @spline.getPoint(@currentTime)

    @cars[0].position.copy(pos).add(new THREE.Vector3(0,5,0).applyMatrix4(mat))
    @cars[0].rotation.setFromRotationMatrix(mat)
