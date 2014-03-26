class LW.FoundationNode
  size: 7
  position: null
  rotation: 0
  height: 10
  offsetHeight: 5

  constructor: (x, y, z, options) ->
    @position = new THREE.Vector3(x, y, z)
    LW.mixin(this, options)

class LW.FreeNode
  position: null
  offsetHeight: 0

  constructor: (x, y, z) ->
    @position = new THREE.Vector3(x, y, z)

class LW.TrackConnectionNode
  position: null
  segment: 0
  offsetHeight: -4

  constructor: (x, y, z) ->
    @position = new THREE.Vector3(x, y, z)

class LW.SupportTube
  node1: null
  node2: null
  type: 0

  size: 1
  isBox: false

  constructor: (@node1, @node2, @type) ->
    @size = switch type
      when 0 then 1.15 # medium
      when 1 then 1.9 # large
      when 2 then 0.7 # tiny
      when 3 then 0.9 # lbeam
      when 4 then 0.9 # hbeam
      when 5 then 2.6 # xlarge
      when 6 then 3.5 # xxlarge

    @isBox = type in [3, 4]
