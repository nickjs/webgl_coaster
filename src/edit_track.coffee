CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0xdddddd
SELECTED_COLOR = 0xffffff

class LW.EditTrack extends THREE.Object3D
  debugNormals: false

  constructor: (@spline) ->
    super()

    @arrows = []

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
        @selected.pointLine.geometry.verticesNeedUpdate = true

        oppositeHandle = if @selectedHandle == @selected.left then @selected.right else @selected.left
        oppositeHandle.position.copy(@selectedHandle.position).negate()

      @selected.splineVector.copy(@selected.position)
      @selected.left.splineVector.copy(@selected.left.position)
      @selected.right.splineVector.copy(@selected.right.position)

    if @selected || force
      @spline.rebuild()

      if !@rerenderTimeout
        @rerenderTimeout = setTimeout =>
          localStorage.setItem('track', JSON.stringify(@spline))

          @rerenderTimeout = null
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

    LW.selectionChanged(node)

  renderTrack: ->
    @clear()

    @controlPoints = []
    lastNode = null

    return if LW.onRideCamera

    for vector, i in @spline.vectors
      isControl = (i - 1) % 3 == 0

      node = new LW.EditNode(isControl)
      node.position.copy(vector)
      node.splineVector = vector

      if isControl
        @add(node)
        node.left = lastNode
        node.add(lastNode)
        @controlPoints.push(node)
      else if lastNode?.isControl
        lastNode.add(node)
        lastNode.right = node
        lastNode.addLine()

      lastNode = node

    @renderCurve()

  renderCurve: ->
    @remove(@line) if @line
    @remove(arrow) for arrow in @arrows
    return if LW.onRideCamera

    geo = @spline.createPointsGeometry(@spline.getLength())
    mat = new THREE.LineBasicMaterial(color: 0xff0000, linewidth: 2)
    @line = new THREE.Line(geo, mat)
    @add(@line)

    return

class LW.EditNode extends THREE.Mesh
  constructor: (@isControl) ->
    geo = new THREE.SphereGeometry(1)
    mat = new THREE.MeshLambertMaterial(color: if isControl then CONTROL_COLOR else POINT_COLOR)

    super(geo, mat)
    @visible = isControl

  addLine: ->
    geo = new THREE.Geometry

    geo.vertices.push(@left.position)
    geo.vertices.push(new THREE.Vector3)
    geo.vertices.push(@right.position)

    mat = new THREE.LineBasicMaterial(color: POINT_COLOR, linewidth: 4)

    @pointLine = new THREE.Line(geo, mat)
    @pointLine.visible = false
    @add(@pointLine)

  select: (selected) ->
    @material.color.setHex(if selected then SELECTED_COLOR else CONTROL_COLOR)

    @left?.visible = selected
    @right?.visible = selected
    @pointLine?.visible = selected
