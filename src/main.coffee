#= require_self
#= require utils

#= require bezier_spline
#= require nurbs_spline
#= require roll_spline
#= require track_model

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
    @renderer = new LW.Renderer(container)

    @terrain = new LW.Terrain

    @edit = new LW.EditController
    @gui = new LW.GUIController

    @gui.loadTracks(true)

    @renderer.render()

  setModel: (@model) ->
    @renderer.scene.remove(@track) if @track

    @train?.stop()
    @renderer.scene.remove(@train) if @train

    klass = LW.TrackModel.classForTrackStyle(model.trackStyle)
    @track = new klass
    @renderer.scene.add(@track)

    @train = new LW.Train(@track, numberOfCars: model.carsPerTrain)
    @renderer.scene.add(@train)

    @gui?.modelChanged(model)
    @edit?.modelChanged(model)

  kill: ->
    @renderer.kill()

window.onload = -> LW.init()
