class LW.TerrainModel
  groundWidth: 9000
  groundHeight: 9000
  groundSegmentsX: 128
  groundSegmentsZ: 128

  objects: null
  heightMap: null

  useWater: false
  waterLevel: 0.0

  constructor: (options) ->
    @objects = []
    @heightMap = []
    LW.mixin(this, options)

class LW.TerrainMesh extends THREE.Object3D
  constructor: ->
    super()
    @loadTextures()

  buildWater: (width, height) ->
    waterNormals = LW.textures.waternormals
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

  rebuild: (park) ->
    @clear()

    terrain = park?.terrain
    return if !terrain

    @groundGeo = new THREE.PlaneGeometry(terrain.groundWidth, terrain.groundHeight, terrain.groundSegmentsX - 1, terrain.groundSegmentsZ - 1)
    @groundGeo.applyMatrix(new THREE.Matrix4().makeRotationX(-Math.PI / 2))

    if terrain.heightMap?.length
      for height, i in terrain.heightMap
        @groundGeo.vertices[i].y = height

    @ground = new THREE.Mesh(@groundGeo, @groundMaterial)
    @ground.receiveShadow = true
    @add(@ground)

    @sky = new THREE.Sky
    @add(@sky.mesh)

    @sunPosition = 0

    uniforms = @sky.uniforms
    uniforms.turbidity.value = 10
    uniforms.reileigh.value = 2
    uniforms.luminance.value = 1

    if terrain.useWater
      @buildWater(terrain.groundWidth, terrain.groundHeight)
      @waterMesh.position.y += terrain.waterLevel if terrain.waterLevel?

    for object in terrain.objects
      model = new LW.Model(LW.models.tree1)
      model.position.copy(object.position)
      @add(model)

  distance = 400000

  update: (delta) ->
    inclination = @sunPosition += 0.005 * delta
    @sunPosition = -0.5 if @sunPosition > 0.5

    azimuth = 0.25
    theta = Math.PI * (inclination - 0.5)
    phi = Math.PI * (azimuth - 0.5)

    x = distance * Math.cos(phi) * Math.sin(theta)
    y = distance * Math.sin(phi) * Math.sin(theta)
    z = distance * Math.sin(phi) * Math.cos(theta)
    @sky?.uniforms.sunPosition.value.set(x, y, z)

    @water?.material.uniforms.time.value += 0.5 / 60.0
    @water?.render()
