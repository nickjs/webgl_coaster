class LW.TrackModel
  constructor: (@points) ->
    @rebuild()

  rebuild: ->
    knots = [0,0,0,0]

    for p, i in @points
      knot = (i + 1) / (@points.length - 3)
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @spline = new THREE.NURBSCurve(3, knots, @points)

  isConnected: false

  getBankAt: (t) ->
    return 0
