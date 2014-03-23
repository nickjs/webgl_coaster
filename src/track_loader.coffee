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
  track.spline.isConnected = true
  track.spline.rebuild()

  track.trackStyle = json.track.style
  track.carsPerTrain = json.track.num_cars

  applyColors = (source, target) ->
    keys =
      spine_color: "spineColor"
      crosstie_color: "tieColor"
      rail_color: "railColor"

    for nlKey, lwKey of keys
      color = source[nlKey]
      target[lwKey] = "rgb(#{color.r}, #{color.g}, #{color.b})"

    return

  applyColors(json.track, track)

  types = ['TrackSegment', 'StationSegment', 'LiftSegment', 'TransportSegment', 'BreakSegment']

  for s, i in json.segments.segments
    sep = new LW.Separator
    sep.position = track.findTFromPoint(track.vertices[i].position)
    sep.type = types[s.type]
    applyColors(s, sep) if s.individual_track_color
    track.separators.push(sep)

  return track
