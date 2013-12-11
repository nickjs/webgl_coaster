CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0xdddddd
SELECTED_COLOR = 0xffffff

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

          @spline.rebuild()
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
    lastNode = null

    @spline = LW.spline if @spline != LW.spline
    return if !@spline # or LW.onRideCamera

    for point, i in @spline.points
      node = new LW.PointEditor(point)
      @add(node)
      @controlPoints.push(node)

    @renderCurve()

  renderCurve: ->
    @remove(@line) if @line
    return if LW.onRideCamera

    geo = @spline.createPointsGeometry(@spline.getLength())
    mat = new THREE.LineBasicMaterial(color: 0xff0000, linewidth: 2)
    @line = new THREE.Line(geo, mat)
    @add(@line)

    return

class LW.PointEditor extends THREE.Mesh
  constructor: (@point) ->
    geo = new THREE.SphereGeometry(1)
    controlMaterial = new THREE.MeshLambertMaterial(color: CONTROL_COLOR)
    pointMaterial = new THREE.MeshLambertMaterial(color: POINT_COLOR)

    super(geo, controlMaterial)

    @position = point.position
    @isControl = true

    @left = new THREE.Mesh(geo, pointMaterial)
    @left.position = point.left
    @left.visible = false
    @add(@left)

    @right = new THREE.Mesh(geo, pointMaterial)
    @right.position = point.right
    @right.visible = false
    @add(@right)

    lineGeo = new THREE.Geometry
    lineGeo.vertices.push(point.left)
    lineGeo.vertices.push(new THREE.Vector3)
    lineGeo.vertices.push(point.right)

    @line = new THREE.Line(lineGeo, new THREE.LineBasicMaterial(color: POINT_COLOR, linewidth: 4))
    @line.visible = false
    @add(@line)

  select: (selected) ->
    @material.color.setHex(if selected then SELECTED_COLOR else CONTROL_COLOR)

    @left?.visible = selected
    @right?.visible = selected
    @line?.visible = selected
