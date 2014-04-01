SEGMENT_TYPES = ['TrackSegment', 'StationSegment', 'LiftSegment', 'TransportSegment', 'BrakeSegment']

class LW.TrackMesh extends THREE.Object3D
  segments: null

  constructor: (options) ->
    super()
    LW.mixin(this, options)

  rebuild: ->
    @clear()
    @segments = []

    @model = LW.model if @model != LW.model
    return if !@model

    for separator, i in @model.separators
      nextSeparator = separators[i + 1]
      separator.length = (nextSeparator?.position ? 1) - separator.position

      segment = new @constructor[SEGMENT_TYPES[separator.type]](separator)
      @segments.push(segment)

    return this

  class @TrackSegment extends THREE.Object3D
    constructor: (@separator, @model) ->
      super()
      @rebuild()

    rebuild: ->



  class @StationSegment extends @TrackSegment
  class @LiftSegment extends @TrackSegment
  class @TransportSegment extends @TrackSegment
  class @BrakeSegment extends @TrackSegment
