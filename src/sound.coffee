context = new (webkitAudioContext || AudioContext)
context.masterGain = context.createGain()
context.masterGain.connect(context.destination)

class LW.Sound
  @context: context
  @update: (mainCamera) ->
    context.listener.setPosition(mainCamera.position.x, mainCamera.position.y, mainCamera.position.z)

  @muteAll: ->
    context.masterGain.gain.value = 0
  @unmuteAll: ->
    context.masterGain.gain.value = 1

  loop: false
  volume: 1.0
  playbackRate: 1.0
  position: null

  isPlaying: false

  constructor: (options) ->
    LW.mixin(this, options)
    @loadBuffer(options.url) if options.url

  loadBuffer: (url) ->
    request = new XMLHttpRequest
    request.open 'GET', url, true
    request.responseType = 'arraybuffer'

    _this = this
    request.onload = ->
      context.decodeAudioData this.response, (buffer) ->
        _this.buffer = buffer
        _this.start() if _this.triedToPlay

    request.send()

  start: (delay) ->
    return if @isPlaying
    return @triedToPlay = true if !@buffer

    @source = context.createBufferSource()
    @source.buffer = @buffer

    @gain = context.createGain()
    @source.connect(@gain)

    if @position
      @panner = context.createPanner()
      @panner.connect(context.masterGain)
      @gain.connect(@panner)
    else
      @gain.connect(context.masterGain)

    @update()

    @source.start(delay)
    @isPlaying = true

  stop: (delay) ->
    @source.stop(delay) if @isPlaying
    @isPlaying = false

  update: (options) ->
    LW.mixin(this, options) if options

    @source?.loop = @loop
    @source?.playbackRate.value = @playbackRate

    @gain?.gain.value = @volume

    @panner?.setPosition(@position.x, @position.y, @position.z) if @position
