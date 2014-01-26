MODES = {
  SELECT: 'select'
  ADD_ROLL: 'add roll'
  ADD_STYLE: 'add style'
}

class LW.EditController
  @MODES = MODES
  mode: MODES.SELECT

  LW.mixin(@prototype, LW.Observable)

  constructor: ->
    renderer = LW.renderer

    @mesh = new LW.EditMesh
    renderer.scene.add(@mesh)

    @selection = []

    @mouseDown = new THREE.Vector2
    @mouseUp = new THREE.Vector2

    @projector = new THREE.Projector
    @raycaster = new THREE.Raycaster

    @transformControl = new THREE.TransformControls(renderer.camera, renderer.domElement)
    renderer.scene.add(@transformControl)

    @transformControl.addEventListener 'change', =>
      @controls.enabled = @transformControl.axis == undefined
    @transformControl.addEventListener 'move', =>
      @changed()

    @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    @controls.addEventListener 'change', =>
      @mesh.transformControl?.update()

    LW.renderer.domElement.addEventListener('mousedown', @onMouseDown, false)
    LW.renderer.domElement.addEventListener('mouseup', @onMouseUp, false)

  setModel: (model) ->
    @model = model
    @mesh.setModel(model)

  selectNode: (node) ->
    return if @selected == node
    oldSelected = @selected

    if oldSelected instanceof LW.Separator
      oldSelected.wireframeColor?.setStyle(@model.wireframeColor)
      line.geometry.colorsNeedUpdate = true for line in LW.track.meshes
    else
      oldSelected?.material.color.setHex(oldSelected.defaultColor)
      oldSelected?.defaultColor = null

    @transformControl.detach()

    @selected = node

    oldWireframe = LW.track?.wireframe
    LW.track?.wireframe = !!node
    LW.track?.rebuild() if oldWireframe != LW.track?.wireframe

    if node instanceof LW.Separator
      node.wireframeColor?.setHex(0xffffff)
      line.geometry.colorsNeedUpdate = true for line in LW.track.meshes
    else if node
      node.defaultColor ||= node.material.color.getHex()
      node.material.color.setHex(SELECTED_COLOR)

      @transformControl.attach(node) if node.isVertex

      LW.train?.stop()
    else
      LW.train?.start()

    @fire('selectionChanged', node, oldSelected)

  changed: (fireEvent) ->
    if @selected
      if @selected.isVertex
        @selected.point.copy(@selected.position)
      else
        @selected.position.copy(@model.spline.getPointAt(@selected.point.x))

    if !@rerenderTimeout
      @rerenderTimeout = setTimeout =>
        @rerenderTimeout = null

        @rerender() # things have only moved, we don't need a full rebuild
        LW.track?.rebuild()
      , 50

    @fire('nodeChanged', @selected) if fireEvent != false

  pick: (pos, objects, deep) ->
    camera = @controls.camera
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

      if Array.isArray(objects)
        return ray.intersectObjects(objects, deep)
      else
        return ray.intersectObject(objects, deep)

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
          intersects = @pick(@mouseUp, @nodes.concat(LW.track.meshes))
          if object = intersects[0]?.object
            if object.trackSegment
              t = @model.positionOnSpline(intersects[0].point)
              object = @model.getSegmentForPosition(t)

          @selectNode(object)

        when MODES.ADD_ROLL
          intersects = @pick(@mouseUp, LW.track, true)
          if point = intersects[0]?.point
            @model.addRollPoint(@model.positionOnSpline(point), 0)
            @rebuild()
            LW.track.rebuild()

        when MODES.ADD_STYLE
          intersects = @pick(@mouseUp, LW.track, true)
          if point = intersects[0]?.point
            @model.addSeparator(@model.positionOnSpline(point), SEPARATORS.STYLE)
            @rebuild()
            LW.track.rebuild()

    @isMouseDown = false
