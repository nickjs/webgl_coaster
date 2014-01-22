class LW.RollCurve
  constructor: (@points) ->
    @rebuild()

  rebuild: ->
    @points.sort (a, b) -> a.x - b.x

  getPoint: (t) ->
    point = (@points.length - 1) * t
    intPoint = Math.floor(point)
    weight = point - intPoint

    a = if intPoint == 0 then intPoint else intPoint - 1
    b = intPoint
    c = if intPoint > @points.length - 2 then @points.length - 1 else intPoint + 1
    d = if intPoint > @points.length - 3 then @points.length - 1 else intPoint + 2

    return THREE.Curve.Utils.interpolate(@points[a].y, @points[b].y, @points[c].y, @points[d].y, weight)
