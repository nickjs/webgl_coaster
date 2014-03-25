class LW.TerrainModel
  groundWidth: 9000
  groundHeight: 9000
  groundSegmentsX: 128
  groundSegmentsZ: 128

  heightMap: null

  constructor: (options) ->
    @heightMap = []
    LW.mixin(this, options)

class LW.TerrainMesh extends THREE.Object3D
  constructor: ->
    super()
    @loadTextures()

  loadTextures: ->
    # Ground
    @groundMaterial ||= new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111)

    groundTexture = THREE.ImageUtils.loadTexture "/resources/textures/grass.jpg", undefined, =>
      groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
      groundTexture.repeat.set(25, 25)
      groundTexture.anisotropy = 16

      @groundMaterial.map = groundTexture
      @groundMaterial.needsUpdate = true

      if @ground
        @groundGeo.buffersNeedUpdate = true
        @groundGeo.uvsNeedUpdate = true

    # Skybox
    path = '/resources/textures/skybox/'
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

    @sky = new THREE.Mesh(new THREE.CubeGeometry(10000, 10000, 10000), @skyMaterial)
    @add(@sky)
