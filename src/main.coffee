#= require_self
#= require observable

#= require gui_controller
#= require renderer
#= require roll_curve
#= require terrain
#= require track_mesh
#= require track_model
#= require train

#= require edit_track
#= require bm_sitdown_track
#= require bm_inverted_track

# Some THREE objects don't create their prototype constructor chains correctly
THREE.Mesh::constructor = THREE.Mesh
THREE.CurvePath::constructor = THREE.CurvePath

THREE.Object3D::clear = ->
  child = @children[0]
  while child
    @remove(child)
    child = @children[0]

THREE.Vector4::copy = (v) ->
  @x = v.x
  @y = v.y
  @z = v.z

  if v.w?
    @w = v.w
  if !@w?
    @w = 1

window.LW =
  init: (container = document.body) ->
    renderer = @renderer = new LW.Renderer(container)

    terrain = new LW.Terrain(renderer)

    @edit = new LW.EditTrack
    renderer.scene.add(@edit)

    @track = new LW.BMInvertedTrack
    renderer.scene.add(@track)

    @train = new LW.Train(@track, numberOfCars: 4)
    @train.start()
    renderer.scene.add(@train)

    @gui = new LW.GUIController

    controls = @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    controls.center.copy(@edit.position)
    controls.addEventListener 'change', =>
      @edit?.transformControl?.update()

    renderer.render()

  mixin: (context, mixin) ->
    for own key, val of mixin
      context[key] = val

LW.UP = new THREE.Vector3(0, 1, 0)
normal = new THREE.Vector3
binormal = new THREE.Vector3
appliedOffset = new THREE.Vector3
matrix = new THREE.Matrix4

LW.positionObjectOnSpline = (object, spline, u, offset, offsetRotation) ->
  pos = spline.getPointAt(u)
  tangent = spline.getTangentAt(u).normalize()

  bank = THREE.Math.degToRad(@model.getBankAt(u))
  binormal.copy(LW.UP).applyAxisAngle(tangent, bank)

  normal.crossVectors(tangent, binormal).normalize()
  binormal.crossVectors(normal, tangent).normalize()

  matrix.set(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

  object.position.copy(pos)

  if offset
    appliedOffset.copy(offset)
    object.position.add(appliedOffset.applyMatrix4(matrix))

  if offsetRotation
    matrix.multiply(offsetRotation)

  object.rotation.setFromRotationMatrix(matrix)
  return tangent

window.onload = -> LW.init()
