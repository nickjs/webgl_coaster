CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0x00ee00
SELECTED_COLOR = 0xffffff

class LW.EditTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()

    @projector = new THREE.Projector

    @mouse = new THREE.Vector2
    @offset = new THREE.Vector3

    @controlPoints = []

    @plane = new THREE.Mesh( new THREE.PlaneGeometry( 2000, 2000, 8, 8 ), new THREE.MeshBasicMaterial( { color: 0x000000, opacity: 0.25, transparent: true, wireframe: true } ) );
    # @plane.visible = false;
    @add(@plane)

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

  renderTrack: ->
    lastNode = null
    for curve, i in @spline.beziers
      for j in [0..3]
        continue if j == 0 and i > 0
        isControl = j in [0, 3]

        node = new LW.EditNode(isControl)
        node.position = curve["v#{j}"]
        @add(node)

        if isControl
          node.left = lastNode
          @controlPoints.push(node)
        else
          lastNode.right = node

        lastNode = node

class LW.EditNode extends THREE.Mesh
  constructor: (@isControl) ->
    geo = new THREE.SphereGeometry(1)
    mat = new THREE.MeshLambertMaterial(color: if isControl then CONTROL_COLOR else POINT_COLOR)

    super(geo, mat)
    @visible = isControl

  select: (selected) ->
    @material.color.setHex(if selected then SELECTED_COLOR else if @isControl then CONTROL_COLOR else POINT_COLOR)
    @left?.visible = selected
    @right?.visible = selected
