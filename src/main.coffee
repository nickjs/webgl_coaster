#= require_self
#= require ./utils

#= require ./bezier_spline
#= require ./nurbs_spline
#= require ./roll_spline
#= require ./track_model

#= require ./controls
#= require ./renderer
#= require ./terrain
#= require ./train
#= require ./supports
#= require ./track_mesh
#= require ./edit_mesh

#= require ./edit_controller
#= require ./gui_controller

#= require ./bm_sitdown_track
#= require ./bm_inverted_track

#= require ./track_loader

window.BASE_URL ?= "/resources"

window.LW =
  init: (container = document.body) ->
    @renderer = new LW.Renderer(container)
    @controls = new LW.Controls([@renderer.topCamera, @renderer.sideCamera, @renderer.frontCamera, @renderer.camera], @renderer.domElement)

    @terrain = new LW.TerrainMesh
    @renderer.scene.add(@terrain)

    @gui = new LW.GUIController

    @renderer.render()

  getTrain: ->
    if !@train
      @train = new LW.Train(@track, numberOfCars: @model.carsPerTrain)
      @renderer.scene.add(@train)

    return @train

  setModel: (@model) ->
    @renderer.scene.remove(@track) if @track

    if @train
      @train.stop()
      @renderer.scene.remove(@train)
      @train = null

    klass = LW.TrackModel.classForTrackStyle(model.trackStyle)
    @track = new klass
    @renderer.scene.add(@track)

    @gui?.modelChanged(model)
    @edit?.modelChanged(model)
    @terrain?.rebuild()
    @track?.rebuild()

  kill: ->
    @renderer.kill()
