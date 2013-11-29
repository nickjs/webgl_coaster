CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0xdddddd
SELECTED_COLOR = 0xffffff

class LW.EditTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()

    @projector = new THREE.Projector

    @mouse = new THREE.Vector2
    @offset = new THREE.Vector3

    @plane = new THREE.Mesh( new THREE.PlaneGeometry( 2000, 2000, 8, 8 ), new THREE.MeshBasicMaterial( { color: 0x000000, opacity: 0.25, transparent: true, wireframe: true } ) );
    # @plane.visible = false;


    LW.renderer.domElement.addEventListener('mousedown', @onMouseDown, false)
    LW.renderer.domElement.addEventListener('mouseup', @onMouseUp, false)
    LW.renderer.domElement.addEventListener('mousemove', @onMouseMove, false)

  onMouseDown: (event) =>
    event.preventDefault()

    vector = new THREE.Vector3(@mouse.x, @mouse.y, 1)
    @projector.unprojectVector(vector, LW.renderer.camera)

    raycaster = new THREE.Raycaster(LW.renderer.camera.position, vector.sub(LW.renderer.camera.position).normalize())

    intersects = raycaster.intersectObjects(@controlPoints)

    if intersects.length > 0
      LW.controls?.enabled = false
      @wantsToDeselect = false

      if @selected != intersects[0].object
        @selected?.select(false)

        @selected = intersects[0].object
        @selected.select(true)

        @add(@plane)
        @plane.position.copy(@selected.position)
        @plane.lookAt(LW.renderer.camera.position)

        intersects = raycaster.intersectObject(@plane)
        @offset.copy(intersects[0].point).sub(@plane.position) if intersects.length

        @isDragging = true
    else
      @wantsToDeselect = true
      @isDragging = false

    @mouseDown = true

  onMouseUp: (event) =>
    event.preventDefault()

    LW.controls?.enabled = true

    if @wantsToDeselect
      @selected?.select(false)
      @selected = null

    @mouseDown = false
    @isDragging = false

  onMouseMove: (event) =>
    @mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
    @mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;

    @wantsToDeselect = false if @mouseDown
    return if not @selected or not @isDragging

    vector = new THREE.Vector3(@mouse.x, @mouse.y, 1)
    @projector.unprojectVector(vector, LW.renderer.camera)

    raycaster = new THREE.Raycaster(LW.renderer.camera.position, vector.sub(LW.renderer.camera.position).normalize())

    intersects = raycaster.intersectObject(@plane)
    @selected.position.copy(intersects[0].point.sub(@offset)) if intersects.length

    if !@rerenderTimeout
      @rerenderTimeout = setTimeout =>
        @rerenderTimeout = null
        @renderCurve()
        LW.track.renderTrack()
      , 10

  selectNode: (node) ->
    if not node
      node = @controlPoints[@controlPoints.length - 1]

    @selected?.select(false)
    @selected = node
    node.select(true)

  renderTrack: ->
    @clear()

    @controlPoints = []
    lastNode = null

    for vector, i in @spline.vectors
      isControl = (i - 1) % 3 == 0

      node = new LW.EditNode(isControl)
      node.position = vector
      @add(node)

      if isControl
        node.left = lastNode
        @controlPoints.push(node)
      else if lastNode?.isControl
        lastNode.right = node
        lastNode.addLine()

      lastNode = node

    @renderCurve()

  renderCurve: ->
    @remove(@line) if @line

    geo = new THREE.Geometry()
    length = @spline.getLength()
    for i in [0..100]
      pos = @spline.getPoint(i / 100)
      geo.vertices[i] = pos

    mat = new THREE.LineBasicMaterial(color: 0xff0000, linewidth: 2)
    @line = new THREE.Line(geo, mat)
    @add(@line)

class LW.EditNode extends THREE.Mesh
  constructor: (@isControl) ->
    geo = new THREE.SphereGeometry(1)
    mat = new THREE.MeshLambertMaterial(color: if isControl then CONTROL_COLOR else POINT_COLOR)

    super(geo, mat)
    @visible = isControl

  addLine: ->
    geo = new THREE.Geometry
    geo.vertices.push(@left.position)
    geo.vertices.push(@position)
    geo.vertices.push(@right.position)

    mat = new THREE.LineBasicMaterial(color: POINT_COLOR, linewidth: 4)

    @pointLine = new THREE.Line(geo, mat)
    @pointLine.visible = false
    @parent.add(@pointLine)

  select: (selected) ->
    @material.color.setHex(if selected then SELECTED_COLOR else CONTROL_COLOR)
    @left?.visible = selected
    @right?.visible = selected
    @pointLine?.visible = selected
