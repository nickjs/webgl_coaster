#= require_self
#= require ./utils
#= require ./model

#= require ./bezier_spline
#= require ./nurbs_spline
#= require ./roll_spline
#= require ./track_model

#= require ./controls
#= require ./renderer
#= require ./terrain
#= require ./train
#= require ./sound
#= require ./supports
#= require ./track_mesh
#= require ./edit_mesh

#= require ./bm_sitdown_track
#= require ./bm_inverted_track
#= require ./intamin_track

window.BASE_URL ?= "/assets"

window.LW =
  init: (container = document.body) ->
    @renderer = new LW.Renderer(container)
    @controls = new LW.Controls(@renderer.camera, @renderer.domElement)

    @terrain = new LW.TerrainMesh
    @renderer.scene.add(@terrain)

    @renderer.render()

  initializeTextures: (textures) ->
    @textures ||= {}
    for key, image of textures
      texture = new THREE.Texture(image)
      texture.needsUpdate = true
      @textures[key] = texture

  getTrain: ->
    if !@train
      @train = new LW.Train(@park.coasters[0], @park.coasters[0].tracks[0])
      @renderer.scene.add(@train)

    return @train

  initializePark: (@park) ->
    @terrain?.rebuild(park)

    for coaster in park.coasters
      for track in coaster.tracks
        track.mesh = new coaster.trackStyle(track)
        @renderer.scene.add(track.mesh)

    return

  kill: ->
    @renderer.kill()
