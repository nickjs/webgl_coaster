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
    sep.settings = s.settings
    applyColors(s, sep) if s.individual_track_color
    track.separators.push(sep)

  for fund in json.fund.nodes
    node = new LW.FoundationNode(fund.pos_x * SCALE, fund.pos_y * SCALE, fund.pos_z * SCALE)
    track.foundationNodes.push(node)

  prefabSupports = []

  for segment, i in json.rasc.segments
    for rasc in segment.rascs
      point = track.spline.curves[i].getPointAt(rasc.pos)
      node = new LW.TrackConnectionNode(point.x, point.y, point.z)
      node.segment = i
      track.trackConnectionNodes.push(node)

      switch rasc.type
        when 2 # simple
          fund = new LW.FoundationNode(point.x, point.y, point.z)
          prefabSupports.push(fund)

          type = if point.y < 25
            2
          else if point.y < 75
            0
          else
            1

          tube = new LW.SupportTube(node, fund, type)
          prefabSupports.push(tube)

        when 5, 7 # double, 90 degree
          free = new LW.FreeNode(point.x, point.y - point.y * 0.2, point.z)
          prefabSupports.push(fund)

          fund1 = new LW.FoundationNode(point.x, point.y, point.z)
          prefabSupports.push(fund1)

          tangent = track.spline.curves[i].getTangentAt(rasc.pos)
          tangent.cross(LW.UP).multiplyScalar(point.y * 0.25)

          tangent.negate() if rasc.type == 7
          tangent.add(point)

          fund2 = new LW.FoundationNode(tangent.x, point.y, tangent.z)
          prefabSupports.push(fund2)

          type = if point.y < 25
            2
          else if point.y < 75
            0
          else
            1

          prefabSupports.push(new LW.SupportTube(free, node, type))
          prefabSupports.push(new LW.SupportTube(free, fund1, type))
          prefabSupports.push(new LW.SupportTube(free, fund2, type))

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

  for support in prefabSupports
    if support instanceof LW.SupportTube
      track.supportTubes.push(support)
    else if support instanceof LW.FreeNode
      track.freeNodes.push(support)
    else if support instanceof LW.TrackConnectionNode
      track.trackConnectionNodes.push(support)
    else if support instanceof LW.FoundationNode
      track.foundationNodes.push(support)

  if heights = json.tera?.heights
    track.terrain.groundSegmentsX = height = json.tera.size_x
    track.terrain.groundSegmentsZ = width = json.tera.size_z
    track.terrain.groundWidth = json.tera.size_x * json.tera.scale_x * 5
    track.terrain.groundHeight = json.tera.size_z * json.tera.scale_z * 5

    heightMap = track.terrain.heightMap = new Float32Array(width * height)

    for z in [0...height - 1]
      for x in [0...width - 1]
        heightMap[x + z * width] = heights[z][x] * 5

  if json.tera?.enable_water
    track.terrain.useWater = true
    track.terrain.waterLevel = json.tera.sea_level

  return track
