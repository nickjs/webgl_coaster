class LW.RollSpline
  constructor: (@points) ->
    @rebuild()

  rebuild: ->
    @points.sort (a, b) -> a.position - b.position

  getPoint: (t) ->
    point = (@points.length - 1) * t
    intPoint = Math.floor(point)
    weight = point - intPoint

    a = if intPoint == 0 then intPoint else intPoint - 1
    b = intPoint
    c = if intPoint > @points.length - 2 then @points.length - 1 else intPoint + 1
    d = if intPoint > @points.length - 3 then @points.length - 1 else intPoint + 2

    return THREE.Curve.Utils.interpolate(@points[a].amount, @points[b].amount, @points[c].amount, @points[d].amount, weight)
