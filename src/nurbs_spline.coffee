class LW.NurbsSpline extends THREE.Curve
  constructor: (@vertices) ->

  rebuild: ->
    knots = [0,0,0,0]

    denominator = @vertices.length - 3
    for i in [1..@vertices.length]
      knot = i / denominator
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @curve = new THREE.NURBSCurve(3, knots, @vertices)

  getPoint: (t) ->
    @curve.getPoint(t)
