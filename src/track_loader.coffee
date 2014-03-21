LW.setModel = (@model) ->
  @gui?.modelChanged(model)
  @edit?.modelChanged(model)
  @track?.rebuild()
  @train?.start()

LW.TrackModel.fromNltrackJSON = (json) ->
  points = for p in json.bezier.beziers
    new LW.BezierPoint(
      p.pos_x, p.pos_y, p.pos_z
      p.cp1_x, p.cp1_y, p.cp1_z
      p.cp2_x, p.cp2_y, p.cp2_z
    )

  track = new LW.TrackModel(points, LW.BezierSpline)

  keys =
    spine_color: "spineColor"
    crosstie_color: "tieColor"
    rail_color: "railColor"

  for nlKey, lwKey of keys
    color = json.track[nlKey]
    track[lwKey] = "rgb(#{color.r}, #{color.g}, #{color.b})"

  return track
