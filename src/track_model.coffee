class LW.TrackNode
  position: 0
  isHidden: false

  constructor: (options) ->
    LW.mixin(this, options) if options

  toJSON: ->
    return LW.mixin({}, this)

  fromJSON: (json) ->
    LW.mixin(this, json)

  copy: (other) ->
    LW.mixin(this, other)

class LW.RollNode extends LW.TrackNode
  amount: 0

class LW.Separator extends LW.TrackNode
  @MODE = {
    STYLE: 1
    TYPE: 2
  }

  @TYPE = {
    TRACK: 'TrackSegment'
    STATION: 'StationSegment'
    LIFT: 'LiftSegment'
    TRANSPORT: 'TransportSegment'
    BRAKE: 'BrakeSegment'
  }

  mode: 0
  type: 'TrackSegment'

  individualColors: false
  spineColor: '#ffffff'
  tieColor: '#ffffff'
  railColor: '#ffffff'
  supportColor: '#ffffff'
  wireframeColor: '#0000ff'

  settings: {}

  colorObject: (colorKey, defaultKey) ->
    if @individualColors || @["use_#{colorKey}"]
      @_colorCache ||= {}
      @_colorCache[colorKey] ||= new THREE.Color(@[colorKey] || @[defaultKey])
    else
      @model.defaultSeparator.colorObject(colorKey, defaultKey)

class LW.TrackModel
  vertices: null
  rollNodes: null
  separators: null

  foundationNodes: null
  freeNodes: null
  trackConnectionNodes: null
  supportTubes: null

  isConnected: false
  forceWireframe: false
  debugNormals: false

  defaultSeparator: null

  LW.mixin(@prototype, LW.Observable)

  constructor: (@vertices, @splineClass, @proxy) ->
    return if @proxy

    @defaultSeparator = new LW.Separator(position: null, individualColors: true, model: this)

    @vertices ||= []
    @rollNodes = [
      new LW.RollNode(position: 0, isHidden: true),
      new LW.RollNode(position: 1, isHidden: true)
    ]

    @separators = []

    @foundationNodes = []
    @freeNodes = []
    @trackConnectionNodes = []
    @supportTubes = []

    @spline = new splineClass(@vertices, @rollNodes)

  rebuild: ->
    return if @proxy
    @spline.rebuild()

  getBankAt: (t) ->
    return @spline.getBankAt(t)

  findTFromPoint: (seekingPos) ->
    totalLength = Math.ceil(@spline.getLength())

    bestDistance = 10
    bestT = 0

    for i in [0..totalLength]
      u = i / totalLength
      currentPos = @spline.getPoint(u)
      distance = currentPos.distanceToSquared(seekingPos)
      if distance < bestDistance
        bestDistance = distance
        bestT = u

    return bestT

  findTFromPoints: (input) ->
    totalLength = Math.ceil(@spline.getLength())

    for i in [0..totalLength]
      u = i / totalLength
      currentPos = @spline.getPoint(u)
      for point in input
        distance = currentPos.distanceToSquared(point.position)

        if !point.best? || distance < point.best
          point.t = u
          point.best = distance

    return input

  addRollNode: (position, amount) ->
    rollNode = new LW.RollNode({position, amount})
    @rollNodes.push(rollNode)
    @spline.rollSpline.rebuild()
    return rollNode

  addSeparator: (position, mode) ->
    separator = new LW.Separator({position, mode})
    @separators.push(separator)
    @separators.sort (a, b) -> a.position - b.position
    return separator

  toJSON: ->
    return {
            @name, @isConnected,
            @vertices, @rollNodes, @separators,
            @onRideCamera, @forceWireframe, @debugNormals,
            @spineColor, @tieColor, @railColor, @wireframeColor
           }

  fromJSON: (json) ->
    LW.mixin(this, json)
    return if @proxy

    @vertices = for v in json.vertices
      new THREE.Vector4(v.x, v.y, v.z, v.w)

    @rollNodes = for node in json.rollNodes
      new LW.RollNode(node)

    @separators = for separator in json.separators
      new LW.Separator(separator)

    @rebuild()
    return this
