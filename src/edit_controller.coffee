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
    @transformControls = []

    @mouseDown = new THREE.Vector2
    @mouseUp = new THREE.Vector2

    @projector = new THREE.Projector
    @raycaster = new THREE.Raycaster

    @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    @controls.addEventListener 'change', =>
      for control in @transformControls
        control.update() if control.object
      return

    LW.renderer.domElement.addEventListener('mousedown', @onMouseDown, false)
    LW.renderer.domElement.addEventListener('mouseup', @onMouseUp, false)

  setModel: (model) ->
    @selectMesh(null, true)

    @model = model

    @mesh.setModel(model)

  selectMesh: (mesh, clearSelection) ->
    return if @selection.indexOf(mesh) != -1

    if clearSelection
      while @selection.length
        oldMesh = @selection.pop()
        oldMesh.material.color.setHex(oldMesh.defaultColor)
        oldMesh.defaultColor = null
        oldMesh.transformControl?.detach()

    if mesh
      @selection.push(mesh)

      mesh.defaultColor ||= mesh.material.color.getHex()
      mesh.material.color.setHex(0xffffff)

      @attachTransformControl(mesh)

    @fire('selectionChanged', mesh, @selection)

  attachTransformControl: (object) ->
    for control in @transformControls
      if !control.object
        return control.attach(mesh)

    control = new THREE.TransformControls(LW.renderer.camera, LW.renderer.domElement)
    LW.renderer.scene.add(control)

    control.addEventListener 'change', =>
      @controls.enabled = control.axis == undefined
    control.addEventListener 'move', =>
      @nodeMoved(control.object)

    control.attach(object)
    object.transformControl = control

    @transformControls.push(control)

  nodeMoved: (node) ->
    @model.fire('nodeMoved', node)
    @fire('nodeMoved', node)

    LW.track?.rebuild()

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
          intersects = @pick(@mouseUp, @mesh.nodeMeshes)
          if object = intersects[0]?.object
            # FIXME
            if object.trackSegment
              t = @model.positionOnSpline(intersects[0].point)
              object = @model.getSegmentForPosition(t)

          @selectMesh(object, true)

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
