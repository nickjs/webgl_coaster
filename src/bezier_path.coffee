class LW.BezierPath extends THREE.CurvePath
  @fromJSON: (vectorJSON) ->
    vectors = for v in vectorJSON
      vec = new THREE.Vector3(v.x, v.y, v.z)
      vec.setBank(v.bank) if v.bank
      vec

    return new LW.BezierPath(vectors)

  toJSON: ->
    for vector in @vectors
      vector.toJSON()

  constructor: (@vectors) ->
    throw "wrong number of vectors" if vectors.length % 3 != 0

    super()
    @_buildCurves()

  _buildCurves: ->
    @curves.pop() while @curves.length

    for i in [0..@vectors.length / 3 - 2]
      index = i * 3

      leftCP = @vectors[index + 1]
      rightCP = @vectors[index + 4]
      leftHandle = @vectors[index + 2].clone().add(leftCP)
      rightHandle = @vectors[index + 3].clone().add(rightCP)

      @add(new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP))

    return

  isConnected: false
  connect: ->
    @isConnected = true

    leftCP = @vectors[@vectors.length - 2]
    rightCP = @vectors[1]
    leftHandle = @vectors[@vectors.length - 1].clone().add(leftCP)
    rightHandle = @vectors[0].clone().add(rightCP)

    @curves.push(new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP))

  disconnect: ->
    @isConnected = false
    @curves.pop()

  getBankAt: (t) ->
    d = t * @getLength()
    curveLengths = @getCurveLengths()
    i = 0

    while i < curveLengths.length
      if curveLengths[i] >= d
        diff = curveLengths[i] - d
        curve = @curves[i]
        u = 1 - diff / curve.getLength()

        leftBank = curve.v0?.bank || 0
        rightBank = curve.v3?.bank || 0

        return THREE.Curve.Utils.interpolate(leftBank, leftBank, rightBank, rightBank, u)

      i++

    return 0

  addControlPoint: (pos) ->
    last = @vectors[@vectors.length - 2]

    @vectors.push(new THREE.Vector3(-10, 0, 0))
    @vectors.push(pos.clone())
    @vectors.push(new THREE.Vector3(10, 0, 0))

    @_buildCurves()

THREE.Vector3::toJSON = ->
  obj = {x: @x, y: @y, z: @z}
  obj.bank = @bank if @bank
  return obj

THREE.Vector3::setBank = (amount) ->
  @bank = amount
  return this
