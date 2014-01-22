class LW.TrackModel
  name: ""

  spline: null
  isConnected: false

  onRideCamera: false

  forceWireframe: false
  debugNormals: false

  spineColor: '#ff0000'
  tieColor: '#ff0000'
  railColor: '#ff0000'
  wireframeColor: '#0000ff'

  constructor: (@points) ->
    @rebuild()

  rebuild: ->
    return unless @points?.length > 1
    knots = [0,0,0,0]

    for p, i in @points
      knot = (i + 1) / (@points.length - 3)
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @spline = new THREE.NURBSCurve(3, knots, @points)


  getBankAt: (t) ->
    return 0

  toJSON: ->
    return {
            @name,
            @points, @isConnected,
            @onRideCamera,
            @forceWireframe, @debugNormals,
            @spineColor, @tieColor, @railColor, @wireframeColor
           }

  fromJSON: (json) ->
    LW.mixin(this, json)

    @points = for p in json.points
      new THREE.Vector4(p.x, p.y, p.z, p.w)

    @rebuild()
