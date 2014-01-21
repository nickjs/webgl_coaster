#= require_self
#= require gui_controller
#= require renderer
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

window.LW =
  init: ->
    renderer = @renderer = new LW.Renderer
    document.body.appendChild(renderer.domElement)

    terrain = new LW.Terrain(renderer)

    @edit = new LW.EditTrack()
    renderer.scene.add(@edit)

    @track = new LW.BMInvertedTrack()
    renderer.scene.add(@track)

    @train = new LW.Train(@track, numberOfCars: 4)
    renderer.scene.add(@train)

    @gui = new LW.GUIController

    controls = @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    controls.center.copy(@edit.position)
    controls.addEventListener 'change', =>
      @edit?.transformControl?.update()

    renderer.render()

window.onload = -> LW.init()
