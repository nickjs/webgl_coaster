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

#= require ./bm_sitdown_track
#= require ./bm_inverted_track
#= require ./intamin_track

window.BASE_URL ?= "/resources"

window.LW =
  init: (container = document.body) ->
    @renderer = new LW.Renderer(container)
    @controls = new LW.Controls(@renderer.camera, @renderer.domElement)

    @terrain = new LW.TerrainMesh
    @renderer.scene.add(@terrain)

    @renderer.render()

  initializeTextures: (textures) ->
    @textures ||= {}
    for key, data of textures
      if Array.isArray(data)
        image = []
        for imageData in data
          subImage = new Image
          subImage.src = imageData
          image.push(subImage)
      else
        image = new Image
        image.src = data

      texture = new THREE.Texture(image)
      texture.needsUpdate = true
      @textures[key] = texture

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

    @track = new model.trackStyle
    @renderer.scene.add(@track)

    @gui?.modelChanged(model)
    @edit?.modelChanged(model)
    @terrain?.rebuild()
    @track?.rebuild()

    @controls.yawObject.position.copy(@model.spline.getPointAt(0)).add(@track.onRideCameraOffset)

  kill: ->
    @renderer.kill()
