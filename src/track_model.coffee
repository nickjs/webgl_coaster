class LW.TrackModel
  name: ""

  points: null
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

  constructor: (@points) ->
    @rollPoints = [new THREE.Vector2(0,0), new THREE.Vector2(1,0)]
    @rebuild()

  rebuild: ->
    return unless @points?.length > 1
    knots = [0,0,0,0]

    for p, i in @points
      knot = (i + 1) / (@points.length - 3)
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @spline = new THREE.NURBSCurve(3, knots, @points)

    @rollSpline = new THREE.SplineCurve(@rollPoints)

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

  getBankAt: (t) ->
    return @rollSpline.getPoint(t).y

  toJSON: ->
    return {
            @name, @isConnected,
            @points, @rollPoints,
            @onRideCamera,
            @forceWireframe, @debugNormals,
            @spineColor, @tieColor, @railColor, @wireframeColor
           }

  fromJSON: (json) ->
    LW.mixin(this, json)

    @points = for p in json.points
      new THREE.Vector4(p.x, p.y, p.z, p.w)

    @rollPoints = for p in json.rollPoints
      new THREE.Vector2(p.x, p.y)

    @rebuild()
