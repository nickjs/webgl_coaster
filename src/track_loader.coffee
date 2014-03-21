LW.TrackModel.fromNltrackJSON = (json) ->
  @points = for p in json.bezier.beziers
    new THREE.Vector4(p.pos_x * 5, p.pos_y * 5, p.pos_z * 5, 1)

  keys =
    spine_color: "spineColor"
    crosstie_color: "tieColor"
    rail_color: "railColor"

  for nlKey, lwKey of keys
    color = json.track[nlKey]
    @[lwKey] = "rgba(#{color.r}, #{color.g}, #{color.b}, #{color.a})"

  return this
