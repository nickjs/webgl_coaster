class LW.TerrainModel
  groundWidth: 9000
  groundHeight: 9000
  groundSegmentsX: 128
  groundSegmentsZ: 128

  heightMap: null

  useWater: false
  waterLevel: 0.0

  constructor: (options) ->
    @heightMap = []
    LW.mixin(this, options)

class LW.TerrainMesh extends THREE.Object3D
  constructor: ->
    super()
    @loadTextures()

  buildWater: (width, height) ->
    waterNormals = LW.textures.waterNormals
    waterNormals.wrapS = waterNormals.wrapT = THREE.RepeatWrapping

    @water = new THREE.Water(LW.renderer.renderer, LW.renderer.camera, LW.renderer.scene, {
      textureWidth: 512
      textureHeight: 512
      waterNormals: waterNormals
      alpha: 0.99
      sunDirection: LW.renderer.dirLight.position.normalize()
      sunColor: 0xffffff
      waterColor: 0x001e0f
      distortionScale: 50.0
    })

    @waterMesh = new THREE.Mesh(new THREE.PlaneGeometry(width, height, 5, 5), @water.material)
    @waterMesh.add(@water)
    @waterMesh.rotation.x = -Math.PI / 2
    LW.renderer.scene.add(@waterMesh)

  loadTextures: ->
    # Ground
    groundTexture = LW.textures.grass
    groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
    groundTexture.repeat.set(25, 25)
    groundTexture.anisotropy = 16

    @groundMaterial = new THREE.MeshLambertMaterial(map: groundTexture)

    # Skybox
    skyTexture = LW.textures.skyBox
    skyTexture.flipY = false

    shader = THREE.ShaderLib["cube"]
    shader.uniforms["tCube"].value = skyTexture

    @skyMaterial = new THREE.ShaderMaterial({
      fragmentShader: shader.fragmentShader
      vertexShader: shader.vertexShader
      uniforms: shader.uniforms
      side: THREE.BackSide
    })

  rebuild: ->
    @clear()

    @model = LW.model if @model != LW.model
    return if !@model

    terrain = @model.terrain

    @groundGeo = new THREE.PlaneGeometry(terrain.groundWidth, terrain.groundHeight, terrain.groundSegmentsX - 1, terrain.groundSegmentsZ - 1)
    @groundGeo.applyMatrix(new THREE.Matrix4().makeRotationX(-Math.PI / 2))

    if terrain.heightMap?.length
      for height, i in terrain.heightMap
        @groundGeo.vertices[i].y = height

    @ground = new THREE.Mesh(@groundGeo, @groundMaterial)
    @ground.receiveShadow = true
    @add(@ground)

    @sky = new THREE.Mesh(new THREE.BoxGeometry(10000, 10000, 10000), @skyMaterial)
    @add(@sky)

    if terrain.useWater
      @buildWater(terrain.groundWidth, terrain.groundHeight)
      @waterMesh.position.y += terrain.waterLevel if terrain.waterLevel?

  update: (delta) ->
    @water?.material.uniforms.time.value += 0.5 / 60.0
    @water?.render()
