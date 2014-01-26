#= require_self
#= require utils

#= require track_model
#= require roll_curve

#= require renderer
#= require terrain
#= require train
#= require track_mesh
#= require edit_mesh

#= require edit_controller
#= require gui_controller

#= require bm_sitdown_track
#= require bm_inverted_track

window.LW =
  init: ->
    renderer = @renderer = new LW.Renderer(document.body)

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

window.onload = -> LW.init()
