class LW.NurbsSpline extends THREE.NURBSCurve
  constructor: (@vertices) ->

  rebuild: ->
    knots = [0,0,0,0]

    denominator = @vertices.length - 3
    for i in [1..@vertices.length]
      knot = i / denominator
      knots.push(THREE.Math.clamp(knot, 0, 1))

    THREE.NURBSCurve.call(this, 3, knots, @vertices)
