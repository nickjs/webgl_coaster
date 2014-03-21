#= require_self
#= require ./utils

#= require ./bezier_spline
#= require ./nurbs_spline
#= require ./roll_spline
#= require ./track_model

#= require ./renderer
#= require ./terrain
#= require ./train
#= require ./track_mesh
#= require ./edit_mesh

#= require ./edit_controller
#= require ./gui_controller

#= require ./bm_sitdown_track
#= require ./bm_inverted_track

#= require ./track_loader

window.LW =
  init: (container = document.body) ->
    renderer = @renderer = new LW.Renderer(container)

    terrain = new LW.Terrain(renderer)

    @track = new LW.BMInvertedTrack
    renderer.scene.add(@track)

    @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)

    @gui = new LW.GUIController

    renderer.render()

  kill: ->
    @renderer.kill()
