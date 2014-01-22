CONTROL_COLOR = 0x0000ee
ROLL_NODE_COLOR = 0x00ff00
SELECTED_COLOR = 0xffffff

NODE_GEO = new THREE.SphereGeometry(1)
ROLL_NODE_GEO = new THREE.CubeGeometry(2, 2, 2)

MODES = {
  SELECT: 'select'
  ADD_ROLL: 'add roll'
}

class LW.EditTrack extends THREE.Object3D
  @MODES: MODES
  mode: MODES.SELECT

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

  changed: (fireEvent) ->
    if @selected
      if @selected.isVertex
        @selected.point.copy(@selected.position)
      else
        @selected.position.copy(@model.spline.getPointAt(@selected.point.x))

    if !@rerenderTimeout
      @rerenderTimeout = setTimeout =>
        @rerenderTimeout = null

        @renderCurve()
        LW.track?.rebuild()
      , 50

    @fire('vertexChanged', @selected) if fireEvent != false

  pick: (pos, objects, deep) ->
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
      if Array.isArray(objects)
        return @raycaster.intersectObjects(objects, deep)
      else
        return @raycaster.intersectObject(objects, deep)
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
      switch @mode
        when MODES.SELECT
          intersects = @pick(@mouseUp, @controlPoints)
          @selectNode(intersects[0]?.object)
        when MODES.ADD_ROLL
          intersects = @pick(@mouseUp, LW.track, true)
          if point = intersects[0]?.point
            @model.addRollPoint(@model.positionOnSpline(point), 0)
            @rebuild()
            LW.track.rebuild()

    @isMouseDown = false

  selectNode: (node) ->
    return if @selected == node
    oldSelected = @selected

    @selected?.material.color.setHex(@selected.defaultColor)
    @selected?.defaultColor = null

    @transformControl.detach()

    @selected = node

    LW.track?.wireframe = !!node
    LW.track?.rebuild()

    if node
      node.defaultColor ||= node.material.color.getHex()
      node.material.color.setHex(SELECTED_COLOR)

      @transformControl.attach(node) if node.isVertex

      LW.train?.stop()
    else
      LW.train?.start()

    @fire('selectionChanged', node, oldSelected)

  rebuild: ->
    @clear()
    @controlPoints = []

    @model = LW.model if @model != LW.model
    return if !@model or @model.onRideCamera

    for point, i in @model.points
      node = new THREE.Mesh(NODE_GEO, new THREE.MeshLambertMaterial(color: CONTROL_COLOR))
      node.position.copy(point)
      node.point = point
      node.isVertex = true

      @add(node)
      @controlPoints.push(node)

    for point, i in @model.rollPoints
      node = new THREE.Mesh(ROLL_NODE_GEO, new THREE.MeshLambertMaterial(color: ROLL_NODE_COLOR))
      node.position.copy(@model.spline.getPointAt(point.x))
      node.point = point
      node.isRoll = true

      @add(node)
      @controlPoints.push(node)

    @renderCurve()

  renderCurve: ->
    @remove(@line) if @line
    return if @model.onRideCamera

    geo = new THREE.Geometry
    for point in @model.points
      geo.vertices.push(point)

    mat = new THREE.LineBasicMaterial(color: 0xff0000, linewidth: 2)
    @line = new THREE.Line(geo, mat)
    @add(@line)

    return
