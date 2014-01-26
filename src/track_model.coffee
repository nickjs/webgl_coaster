class LW.TrackModel
  name: ""

  points: null
  rollPoints: null
  separators: null

  spline: null
  rollSpline: null
  isConnected: false

  onRideCamera: false

  forceWireframe: false
  debugNormals: false

  spineColor: '#ff0000'
  tieColor: '#ff0000'
  railColor: '#ff0000'
  wireframeColor: '#0000ff'

  constructor: (@points, @proxy) ->
    return if @proxy

    @rollPoints = [new LW.RollPoint(position: 0, amount: 0, hidden: true), new LW.RollPoint(position: 1, amount: 0, hidden: true)]
    @separators = [new LW.Separator(position: 0, mode: LW.Separator.MODE.TYPE, hidden: true)]

    @rebuild()

  rebuild: ->
    return if @proxy
    return unless @points?.length > 1

    knots = [0,0,0,0]

    for p, i in @points
      knot = (i + 1) / (@points.length - 3)
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @spline = new THREE.NURBSCurve(3, knots, @points)

    @rollSpline ||= new LW.RollCurve(@rollPoints)
    @rollSpline.rebuild()

  positionOnSpline: (seekingPos) ->
    totalLength = Math.ceil(@spline.getLength()) * 10
    bestDistance = 10
    bestT = 0
    for i in [0..totalLength]
      u = i / totalLength
      currentPos = @spline.getPointAt(u)
      distance = currentPos.distanceTo(seekingPos)
      if distance < bestDistance
        bestT = u
        bestDistance = distance

    return bestT

  getSegmentForPosition: (seekingPos) ->
    for separator, i in @separators
      if separator.position >= seekingPos
        return @separators[i - 1]

    return @separators[@separators.length - 1]

  addRollPoint: (position, amount) ->
    @rollPoints.push(new LW.RollPoint({position, amount}))
    @rollSpline.rebuild()

  getBankAt: (t) ->
    return @rollSpline.getPoint(t)

  addSeparator: (position, mode) ->
    @separators.push(new LW.Separator({position, mode}))
    @separators.sort (a, b) -> a.x - b.x

  toJSON: ->
    return {
            @name, @isConnected,
            @points, @rollPoints, @separators,
            @onRideCamera, @forceWireframe, @debugNormals,
            @spineColor, @tieColor, @railColor, @wireframeColor
           }

  fromJSON: (json) ->
    LW.mixin(this, json)
    return if @proxy

    @points = for p in json.points
      new THREE.Vector4(p.x, p.y, p.z, p.w)

    @rollPoints = for p in json.rollPoints
      new LW.RollPoint(p)

    @separators = for p in json.separators
      new LW.Separator(p)

    @rebuild()

class LW.RollPoint
  position: 0
  amount: 0
  hidden: false

  constructor: (options) ->
    LW.mixin(this, options) if options

  toJSON: ->
    json = {}
    for own key, value of this
      json[key] = value
    return json

  copy: (other) ->
    LW.mixin(this, other)

class LW.Separator
  @MODE = {
    STYLE: 1
    TYPE: 2
  }

  position: 0
  mode: 0
  segmentType: 'TrackSegment'
  hidden: false

  constructor: (options) ->
    LW.mixin(this, options) if options

  toJSON: ->
    json = {}
    for own key, value of this
      json[key] = value
    return json

  copy: (other) ->
    LW.mixin(this, other)
