CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0xdddddd
SELECTED_COLOR = 0xffffff

NODE_GEO = new THREE.SphereGeometry(1)

class LW.EditTrack extends THREE.Object3D
  debugNormals: false

  constructor: (@spline) ->
    super()

    @mouseDown = new THREE.Vector2
    @mouseUp = new THREE.Vector2

    @projector = new THREE.Projector
    @raycaster = new THREE.Raycaster

    @transformControl = new THREE.TransformControls(LW.renderer.camera, LW.renderer.domElement)
    LW.renderer.scene.add(@transformControl)

    @transformControl.addEventListener 'change', =>
      LW.controls?.enabled = @transformControl.axis == undefined
      @changed()

    LW.renderer.domElement.addEventListener('mousedown', @onMouseDown, false)
    LW.renderer.domElement.addEventListener('mouseup', @onMouseUp, false)

  changed: (force) ->
    if @selected and @transformControl.axis != undefined
      if @selectedHandle
        @selected.line.geometry.verticesNeedUpdate = true

        oppositeHandle = if @selectedHandle == @selected.left then @selected.right else @selected.left
        oppositeHandle.position.copy(@selectedHandle.position).negate()

    if @selected || force

      if !@rerenderTimeout
        @rerenderTimeout = setTimeout =>
          @rerenderTimeout = null

          @model.rebuild()
          @renderCurve()
          LW.track.rebuild()
        , 10

    return

  pick: (pos, objects) ->
    camera = LW.controls.camera
    {x, y} = pos

    if LW.renderer.useQuadView
      x -= 0.5 if x > 0.5
      y -= 0.5 if y > 0.5

      vector = new THREE.Vector3(x * 4 - 1, -y * 4 + 1 , 0.5)
    else
      vector = new THREE.Vector3(x * 2 - 1, -y * 2 + 1, 0.5)

    if camera instanceof THREE.PerspectiveCamera
      @projector.unprojectVector(vector, camera)
      @raycaster.set(camera.position, vector.sub(camera.position).normalize())
      return @raycaster.intersectObjects(objects)
    else
      ray = @projector.pickingRay(vector, camera)
      return ray.intersectObjects(objects)


  onMouseDown: (event) =>
    @mouseDown.x = event.clientX / window.innerWidth
    @mouseDown.y = event.clientY / window.innerHeight

    @isMouseDown = true

  onMouseUp: (event) =>
    return if !@isMouseDown

    @mouseUp.x = event.clientX / window.innerWidth
    @mouseUp.y = event.clientY / window.innerHeight

    if @mouseDown.distanceTo(@mouseUp) == 0
      nodes = if @selected
        @controlPoints.concat([@selected.left, @selected.right])
      else
        @controlPoints

      intersects = @pick(@mouseUp, nodes)
      @transformControl.detach()

      if intersects.length > 0
        object = intersects[0].object

        if object.isControl
          @selectedHandle = null
          @selectNode(object)
        else
          @selectedHandle = object
          @transformControl.attach(object)
      else
        @selectedHandle = null
        @selectNode(null)

    @isMouseDown = false

  selectNode: (node) ->
    if node == undefined
      node = @controlPoints[@controlPoints.length - 1]

    @selected?.select(false)
    @selected = node

    if node
      node.select(true)
      @transformControl.attach(node)

  rebuild: ->
    @clear()
    @controlPoints = []

    @model = LW.model if @model != LW.model
    return if !@model # or LW.onRideCamera

    for point, i in @model.points
      node = new THREE.Mesh(NODE_GEO, new THREE.MeshLambertMaterial(color: CONTROL_COLOR))
      node.position.copy(point)

      @add(node)
      @controlPoints.push(node)

    @renderCurve()

  renderCurve: ->
    @remove(@line) if @line
    return if LW.onRideCamera

    geo = new THREE.Geometry
    for point in @model.points
      geo.vertices.push(point)

    mat = new THREE.LineBasicMaterial(color: 0xff0000, linewidth: 2)
    @line = new THREE.Line(geo, mat)
    @add(@line)

    return
