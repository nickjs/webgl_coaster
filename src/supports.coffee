class LW.FoundationNode
  size: 7
  position: null
  rotation: 0

  constructor: (x, y, z, options) ->
    @position = new THREE.Vector3(x, y, z)
    LW.mixin(this, options)

class LW.FreeNode
  position: null

  constructor: (x, y, z) ->
    @position = new THREE.Vector3(x, y, z)

class LW.TrackConnectionNode
  position: null
  segment: 0

  constructor: (x, y, z) ->
    @position = new THREE.Vector3(x, y, z)

class LW.SupportTube
  node1: null
  node2: null
  type: 0

  constructor: (@node1, @node2, @type) ->
