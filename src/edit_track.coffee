CONTROL_COLOR = 0x0000ee
POINT_COLOR = 0x00ee00
SELECTED_COLOR = 0xffffff

class LW.EditTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()

    @projector = new THREE.Projector
    @raycaster = new THREE.Raycaster

    @mouse = new THREE.Vector2

    document.addEventListener 'click', (event) =>
      @mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
      @mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;

      @pick()

  renderTrack: ->
    for curve, i in @spline.beziers
      @renderBezier(curve, i > 0)

  renderBezier: (curve, skipFirst) ->
    for i in [0..3]
      continue if i == 0 and skipFirst
      isControl = i in [0, 3]

      geo = new THREE.SphereGeometry(1)
      mat = new THREE.MeshLambertMaterial(color: if isControl then CONTROL_COLOR else POINT_COLOR)
      mesh = new THREE.Mesh(geo, mat)
      mesh.position.copy(curve["v#{i}"])
      if isControl
        mesh.isControl = true
        mesh.left = @lastMesh
      else
        mesh.visible = false
        @lastMesh.right = mesh

      @lastMesh = mesh
      @add(mesh)

  pick: ->
    vector = new THREE.Vector3(@mouse.x, @mouse.y, 1)
    @projector.unprojectVector(vector, LW.renderer.camera)

    @raycaster.set(LW.renderer.camera.position, vector.sub(LW.renderer.camera.position).normalize())

    intersects = @raycaster.intersectObjects(@children, false)

    if intersects.length > 0
      if @intersected != intersects[0].object
        if @intersected
          @intersected.material.color.setHex(CONTROL_COLOR)
          @intersected.left?.visible = false
          @intersected.right?.visible = false

        if intersects[0].object.isControl
          @intersected = intersects[0].object
          @intersected.material.color.setHex(SELECTED_COLOR)
          @intersected.left?.visible = true
          @intersected.right?.visible = true
    else
      if @intersected
          @intersected.material.color.setHex(CONTROL_COLOR)
          @intersected.left?.visible = false
          @intersected.right?.visible = false
          @intersected = null
