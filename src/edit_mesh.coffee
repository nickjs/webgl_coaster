VERTEX_COLOR = 0x0000ee
ROLL_NODE_COLOR = 0x00ff00
STYLE_NODE_COLOR = 0x00ffff
SELECTED_COLOR = 0xffffff

VERTEX_GEO = new THREE.SphereGeometry(1)
ROLL_NODE_GEO = new THREE.CubeGeometry(2, 2, 2)
STYLE_NODE_GEO = new THREE.CubeGeometry(3, 3, 1)

class LW.EditMesh extends THREE.Object3D
  constructor: ->
    super()

    @nodeMeshes = []

  setModel: (model) ->
    oldModel = @model

    if oldModel
      oldModel.forget('nodeAdded', @addNode)
      oldModel.forget('nodeMoved', @nodeMoved)

      @clear()

      vertices = @polygonGeo.vertices
      vertices.pop() while vertices.length > 0

    @model = model

    if model
      model.observe('nodeAdded', @addNode)
      model.observe('nodeMoved', @nodeMoved)

      nodes = @model.vertices.concat(@model.rollNodes, @model.separators)
      @addNode(node, true) for node in nodes
      @rebuildPolygonLine()

  addNode: (node, skipRebuildLine) =>
    return if node.isHidden

    if node instanceof THREE.Vector4
      geo = VERTEX_GEO
      color = VERTEX_COLOR
      pos = node
      isVertex = true

      @rebuildPolygonLine() unless skipRebuildLine

    else if node instanceof LW.RollNode
      geo = ROLL_NODE_GEO
      color = ROLL_NODE_COLOR
      isRollNode = true

    else if node instanceof LW.Separator
      geo = STYLE_NODE_GEO
      color = STYLE_NODE_COLOR
      isSeparator = true

    mesh = new THREE.Mesh(geo, new THREE.MeshLambertMaterial({color}))

    if pos
      mesh.position = pos
    else
      LW.positionObjectOnSpline(mesh, @model.spline, node.position)

    mesh.node = node
    mesh.isVertex = isVertex
    mesh.isRollNode = isRollNode
    mesh.isSeparator = isSeparator

    @nodeMeshes.push(mesh)
    @add(mesh)

  nodeMoved: =>
    @polygonGeo.verticesNeedUpdate = true

  rebuildPolygonLine: ->
    @remove(@polygonLine) if @polygonLine

    @polygonGeo = new THREE.Geometry
    for vertex in @model.vertices
      @polygonGeo.vertices.push(vertex)

    @polygonLine = new THREE.Line(@polygonGeo, new THREE.LineBasicMaterial(color: 0x000000, linewidth: 2))
    @add(@polygonLine)
