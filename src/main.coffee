#= require_self
#= require utils

#= require track_model
#= require roll_spline

#= require renderer
#= require terrain
#= require train
#= require track_mesh
#= require edit_mesh

#= require edit_controller
#= require gui_controller

#= require bm_sitdown_track
#= require bm_inverted_track

#= require track_loader

window.LW =
  init: (container = document.body) ->
    renderer = @renderer = new LW.Renderer(container)

    terrain = new LW.Terrain(renderer)

    @track = new LW.BMInvertedTrack
    renderer.scene.add(@track)

    # @train = new LW.Train(@track, numberOfCars: 4)
    # renderer.scene.add(@train)

    @edit = new LW.EditController
    @gui = new LW.GUIController

    renderer.render()

  kill: ->
    @renderer.kill()

window.onload = -> LW.init()
