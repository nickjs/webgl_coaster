LW.TrackModel.fromNltrackJSON = (json) ->
  SCALE = 5
  points = []

  for p in json.bezier.beziers
    point = new LW.BezierPoint(
      p.pos_x * SCALE, p.pos_y * SCALE, p.pos_z * SCALE,
      p.cp1_x * SCALE, p.cp1_y * SCALE, p.cp1_z * SCALE,
      p.cp2_x * SCALE, p.cp2_y * SCALE, p.cp2_z * SCALE,
    )

    point.setBank(-THREE.Math.radToDeg(p.roll), p.continues_roll, p.relative_roll)
    points.push(point)

  track = new LW.TrackModel(points, LW.BezierSpline)

  if json.segments.segments.length >= json.bezier.beziers.length
    track.spline.isConnected = true
    track.spline.rebuild()

  track.trackStyle = json.track.style
  track.carsPerTrain = json.track.num_cars

  applyColors = (source, target) ->
    keys =
      spine_color: "spineColor"
      crosstie_color: "tieColor"
      rail_color: "railColor"
      supports_color: "supportColor"

    for nlKey, lwKey of keys
      color = source[nlKey]
      if color
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

  for fund in json.fund.nodes
    node = new LW.FoundationNode(fund.pos_x * SCALE, -3, fund.pos_z * SCALE)
    track.foundationNodes.push(node)

  for segment, i in json.rasc.segments
    for rasc in segment.rascs
      point = track.spline.curves[i].getPointAt(rasc.pos)
      node = new LW.TrackConnectionNode(point.x, point.y, point.z)
      node.segment = i
      track.trackConnectionNodes.push(node)

  for fren in json.fren.nodes
    node = new LW.FreeNode(fren.pos_x * SCALE, fren.pos_y * SCALE, fren.pos_z * SCALE)
    track.freeNodes.push(node)

  findNode = (json, key) ->
    type = json["#{key}_type"]
    segment = json["#{key}_segment"]
    index = json["#{key}_index"]

    if type == 3 # track node
      segment_index = 0
      for node in track.trackConnectionNodes
        continue if node.segment != segment
        return node if segment_index == index
        segment_index++

    else if type == 2 # free node
      return track.freeNodes[index]

    else if type == 1 # fund node
      return track.foundationNodes[index]

  for tube in json.tube.tubes
    node1 = findNode(tube, "n1")
    node2 = findNode(tube, "n2")
    continue if !node1 || !node2

    tube = new LW.SupportTube(node1, node2, tube.tube_type)
    track.supportTubes.push(tube)

  return track
