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

  mode: 0
  type: 'TrackSegment'

  spineColor: '#ffffff'
  tieColor: '#ffffff'
  railColor: '#ffffff'
  wireframeColor: '#0000ff'

class LW.TrackModel
  name: ""

  vertices: null
  rollNodes: null
  separators: null

  isConnected: false
  forceWireframe: false
  debugNormals: false

  onRideCamera: false

  defaultSeparator: new LW.Separator(
    position: null
  )

  LW.mixin(@prototype, LW.Observable)

  constructor: (@vertices, @proxy) ->
    return if @proxy

    @vertices ||= []
    @rollNodes = [
      new LW.RollNode(isHidden: true),
      new LW.RollNode(position: 1, isHidden: true)
    ]

    @separators = []

    @rebuild()

  rebuild: ->
    return if @proxy

    knots = [0,0,0,0]

    denominator = @vertices.length - 3
    for i in [1..@vertices.length]
      knot = i / denominator
      knots.push(THREE.Math.clamp(knot, 0, 1))

    @spline = new THREE.NURBSCurve(3, knots, @vertices)

    @rollSpline ||= new LW.RollSpline(@rollNodes)
    @rollSpline.rebuild()

  getBankAt: (t) ->
    return @rollSpline.getPoint(t)

  findTFromPoint: (seekingPos) ->
    totalLength = Math.ceil(@spline.getLength()) * 10
    bestDistance = 10
    bestT = 0
    for i in [0..totalLength]
      u = i / totalLength
      currentPos = @spline.getPointAt(u)
      distance = currentPos.distanceTo(seekingPos)
      if distance < bestDistance
        bestT = u
        bestDistance = distance

    return bestT

  findSeparatorFromT: (seekingT) ->
    for separator in @separators
      if seekingT <= separator.position
        return separator

    return @defaultSeparator

  addRollNode: (position, amount) ->
    rollNode = new LW.RollNode({position, amount})
    @rollNodes.push(rollNode)
    @rollNodes.sort (a, b) -> a.position - b.position
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
