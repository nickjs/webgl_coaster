class LW.BezierPath extends THREE.CurvePath
  @fromJSON: (json) ->
    points = for p in json
      new LW.Point.fromJSON(p)
    return new LW.BezierPath(points)

  toJSON: ->
    for p in @points
      p.toJSON()

  constructor: (@points) ->
    super()
    @rebuild()

  rebuild: ->
    @curves.pop() while @curves.length
    @cacheLengths = []

    for p1, i in @points
      if i == @points.length - 1
        return if !@isConnected
        p2 = @points[0]
      else
        p2 = @points[i + 1]

      leftCP = p1.position
      rightCP = p2.position
      leftHandle = p1.right.clone().add(leftCP)
      rightHandle = p2.left.clone().add(rightCP)

      curve = new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP)
      curve.p1 = p1
      curve.p2 = p2
      @add(curve)

    return

  isConnected: false

  getBankAt: (t) ->
    d = t * @getLength()
    curveLengths = @getCurveLengths()
    i = 0

    while i < curveLengths.length
      if curveLengths[i] >= d
        diff = curveLengths[i] - d
        curve = @curves[i]
        u = 1 - diff / curve.getLength()

        leftBank = curve.p1?.bank || 0
        rightBank = curve.p2?.bank || 0

        return THREE.Curve.Utils.interpolate(leftBank, leftBank, rightBank, rightBank, u)

      i++

    return 0

  addControlPoint: (pos) ->
    last = @vectors[@vectors.length - 2]

    @vectors.push(new THREE.Vector3(-10, 0, 0))
    @vectors.push(pos.clone())
    @vectors.push(new THREE.Vector3(10, 0, 0))

    @rebuild()

class LW.Point
  position: null
  bank: 0
  segmentType: 0

  constructor: (x, y, z, lx, ly, lz, rx, ry, rz) ->
    @position = new THREE.Vector3(x, y, z)
    @left = new THREE.Vector3(lx, ly, lz)
    @right = new THREE.Vector3(rx, ry, rz)

  setBank: (amount) ->
    @bank = amount
    return this

  setSegmentType: (type) ->
    @segmentType = type
    return this

  toJSON: ->
    obj = {position: @position, left: @left, right: @right}
    obj.bank = @bank if @bank
    obj.segmentType = @segmentType if @segmentType
    return obj

  @fromJSON: (json) ->
    p = new LW.Point
    p.position.copy(json.position)
    p.left.copy(json.left)
    p.right.copy(json.right)
    p.bank = json.bank if json.bank
    p.segmentType = json.segmentType if json.segmentType
    return p
