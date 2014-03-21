LW.TrackModel.fromNltrackJSON = (json) ->
  points = []

  for p in json.bezier.beziers
    point = new LW.BezierPoint(
      p.pos_x * 5, p.pos_y * 5, p.pos_z * 5,
      p.cp1_x * 5, p.cp1_y * 5, p.cp1_z * 5,
      p.cp2_x * 5, p.cp2_y * 5, p.cp2_z * 5,
    )

    point.setBank(-THREE.Math.radToDeg(p.roll), p.continues_roll, p.relative_roll)
    points.push(point)

  track = new LW.TrackModel(points, LW.BezierSpline)

  keys =
    spine_color: "spineColor"
    crosstie_color: "tieColor"
    rail_color: "railColor"

  for nlKey, lwKey of keys
    color = json.track[nlKey]
    track[lwKey] = "rgb(#{color.r}, #{color.g}, #{color.b})"

  return track
