class LW.RollSpline
  constructor: (@points) ->

  rebuild: ->
    @points.sort (a, b) -> a.position - b.position

  getPoint: (t) ->
    for point, i in @points
      nextPoint = @points[i + 1]
      if t >= point.position && t <= nextPoint.position
        break

    prevPoint = if point.strict
      point
    else
      @points[i - 1] || @points[@points.length - 1]

    nextNextPoint = if nextPoint.strict
      nextPoint
    else
      @points[i + 2] || @points[0]

    min = point.position
    max = nextPoint.position
    weight = (t - min) / (max - min)

    interpolated = THREE.Curve.Utils.interpolate(prevPoint.amount, point.amount, nextPoint.amount, nextNextPoint.amount, weight)
    return [interpolated, false]
