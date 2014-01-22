CONTROL_COLOR = 0x0000ee
SELECTED_COLOR = 0xffffff

NODE_GEO = new THREE.SphereGeometry(1)

class LW.EditTrack extends THREE.Object3D
  debugNormals: false

  LW.mixin(@prototype, LW.Observable)

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
    @transformControl.addEventListener 'move', =>
      @changed()

    LW.renderer.domElement.addEventListener('mousedown', @onMouseDown, false)
    LW.renderer.domElement.addEventListener('mouseup', @onMouseUp, false)

  changed: ->
    if @selected
      @selected.point.copy(@selected.position)

    if !@rerenderTimeout
      @rerenderTimeout = setTimeout =>
        @rerenderTimeout = null

        @renderCurve()
        LW.track?.rebuild()
      , 50

    @fire('vertexChanged', @selected)

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
      intersects = @pick(@mouseUp, @controlPoints)
      @selectNode(intersects[0]?.object)

    @isMouseDown = false

  selectNode: (node) ->
    return if @selected == node

    @selected?.material.color.setHex(CONTROL_COLOR)
    @transformControl.detach()

    @selected = node

    LW.track?.wireframe = !!node || LW.track.forceWireframe
    @changed()

    if node
      node.material.color.setHex(SELECTED_COLOR)
      @transformControl.attach(node)

      LW.train?.stop()
    else
      LW.train?.start()

  rebuild: ->
    @clear()
    @controlPoints = []

    @model = LW.model if @model != LW.model
    return if !@model # or LW.onRideCamera

    for point, i in @model.points
      node = new THREE.Mesh(NODE_GEO, new THREE.MeshLambertMaterial(color: CONTROL_COLOR))
      node.position.copy(point)
      node.point = point

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
