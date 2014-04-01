class LW.BezierSpline extends THREE.CurvePath
  @fromJSON: (json) ->
    points = for p in json
      new LW.BezierPoint.fromJSON(p)
    return new LW.BezierSpline(points)

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
      leftHandle = p1.right
      rightHandle = p2.left

      curve = new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP)
      curve.p1 = p1
      curve.p2 = p2
      @add(curve)

    return

  isConnected: false

  getCurveAt: (t) ->
    d = t * @getLength()
    curveLengths = @getCurveLengths()
    i = 0

    while i < curveLengths.length
      if curveLengths[i] >= d
        return @curves[i]

      i++

    return null

  getBankAt: (t) ->
    d = t * @getLength()
    curveLengths = @getCurveLengths()
    i = 0

    while i < curveLengths.length
      if curveLengths[i] >= d
        diff = curveLengths[i] - d
        curve = @curves[i]
        u = 1 - diff / curve.getLength()

        p0 = @curves[i - 1]?.p1?.bank
        p1 = curve.p1?.bank
        p2 = curve.p2?.bank
        p3 = @curves[i + 1]?.p2?.bank

        relative = curve.p1?.relativeRoll || curve.p2?.relativeRoll

        # if p0?
        #   if p0 < 0 && p1 < p0 && p2 > 0
        #     p2 = -Math.PI * 2 + p2
        #   else if p0 > 0 && p1 > p0 && p2 < 0
        #     p2 = Math.PI * 2 + p2

        return [THREE.Curve.Utils.interpolate(p0 || p1, p1, p2, p3 || p2, u), relative]

      i++

    return 0

  addControlPoint: (pos) ->
    @points.push(new LW.BezierPoint(pos.x, pos.y, pos.z, -10, 0, 0, 10,0,0))
    @rebuild()

class LW.BezierPoint
  position: null
  bank: 0
  segmentType: 0

  constructor: (x, y, z, lx, ly, lz, rx, ry, rz) ->
    @position = new THREE.Vector3(x, y, z)
    @left = new THREE.Vector3(lx, ly, lz)
    @right = new THREE.Vector3(rx, ry, rz)

  setBank: (@bank, @continuesRoll, @relativeRoll) ->
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
    p = new LW.BezierPoint
    p.position.copy(json.position)
    p.left.copy(json.left)
    p.right.copy(json.right)
    p.bank = json.bank if json.bank
    p.segmentType = json.segmentType if json.segmentType
    return p

