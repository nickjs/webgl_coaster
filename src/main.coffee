#= require_self
#= require bezier_path
#= require gui_controller
#= require spline
#= require renderer
#= require terrain
#= require track
#= require train

#= require edit_track
#= require bm_track

# Some THREE objects don't create their prototype constructor chains correctly
THREE.Mesh::constructor = THREE.Mesh
THREE.CurvePath::constructor = THREE.CurvePath

THREE.Object3D::clear = ->
    child = @children[0]
    while child
      @remove(child)
      child = @children[0]

window.LW =
  init: ->
    renderer = @renderer = new LW.Renderer
    document.body.appendChild(renderer.domElement)

    terrain = new LW.Terrain(renderer)

    @edit = new LW.EditTrack()
    renderer.scene.add(@edit)

    @track = new LW.BMTrack()
    renderer.scene.add(@track)

    @gui = new LW.GUIController

    controls = @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    controls.center.copy(@edit.position)
    controls.addEventListener 'change', =>
      @edit?.transformControl?.update()

    renderer.render()

window.onload = -> LW.init()
