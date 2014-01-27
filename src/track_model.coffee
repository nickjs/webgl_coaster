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

    @rollPoints = [new THREE.Vector2(0,0), new THREE.Vector2(1,0)]
    @separators = []

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
    bestDistance = {t: 0, distance: 10}
    for i in [0..totalLength]
      u = i / totalLength
      currentPos = @spline.getPointAt(u)
      distance = currentPos.distanceTo(seekingPos)
      if distance < bestDistance.distance
        bestDistance.t = u
        bestDistance.distance = distance

    return bestDistance.t

  addRollPoint: (t, amount) ->
    @rollPoints.push(new THREE.Vector2(t, amount))
    @rollSpline.rebuild()

  getBankAt: (t) ->
    return @rollSpline.getPoint(t)

  addSeparator: (t, mode) ->
    @separators.push(new THREE.Vector2(t, mode))
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
      new THREE.Vector2(p.x, p.y)

    @separators = for p in json.separators
      new THREE.Vector2(p.x, p.y)

    @rebuild()
