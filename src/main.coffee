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
    @renderer = new LW.Renderer(container)

    @terrain = new LW.Terrain

    @controls = new THREE.EditorControls([@renderer.topCamera, @renderer.sideCamera, @renderer.frontCamera, @renderer.camera], @renderer.domElement)

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

  kill: ->
    @renderer.kill()
