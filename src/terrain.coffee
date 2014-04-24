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
    waterNormals = THREE.ImageUtils.loadTexture "#{BASE_URL}/textures/waternormals.jpg"
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
    @groundMaterial ||= new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111)

    groundTexture = THREE.ImageUtils.loadTexture "#{BASE_URL}/textures/grass.jpg", undefined, =>
      groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
      groundTexture.repeat.set(25, 25)
      groundTexture.anisotropy = 16

      @groundMaterial.map = groundTexture
      @groundMaterial.needsUpdate = true

      if @ground
        @groundGeo.buffersNeedUpdate = true
        @groundGeo.uvsNeedUpdate = true

    # Skybox
    path = "#{BASE_URL}/textures/skybox/"
    format = '.jpg'
    urls = [
      path + 'px' + format, path + 'nx' + format
      path + 'py' + format, path + 'ny' + format
      path + 'pz' + format, path + 'nz' + format
    ]

    textureCube = THREE.ImageUtils.loadTextureCube(urls, new THREE.CubeRefractionMapping())

    shader = THREE.ShaderLib["cube"]
    shader.uniforms["tCube"].value = textureCube

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
