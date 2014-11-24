class LW.NurbsSpline extends THREE.NURBSCurve
  constructor: (@vertices, @rollNodes) ->
    @rollSpline = new LW.RollSpline(@rollNodes)
    @rebuild()

  rebuild: ->
    knots = [0,0,0,0]

    denominator = @vertices.length - 3
    for i in [1..@vertices.length]
      knot = i / denominator
      knots.push(THREE.Math.clamp(knot, 0, 1))

    degree = 3
    if @vertices.length == 2
      knots = [0,0,1,1]
      degree = 1

    @knots = knots
    THREE.NURBSCurve.call(this, degree, knots, @vertices)

    @rollSpline.rebuild()

  getBankAt: (t) ->
    @rollSpline.getPoint(t)
