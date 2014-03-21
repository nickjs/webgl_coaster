class LW.Terrain
  constructor: ->
    geo = new THREE.PlaneGeometry(9000, 9000, 125, 125)

    groundMaterial = new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111)
    groundTexture = THREE.ImageUtils.loadTexture "/resources/textures/grass.jpg", undefined, ->
      groundMaterial.map = groundTexture
      groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
      groundTexture.repeat.set(25, 25)
      groundTexture.anisotropy = 16;

      @ground = new THREE.Mesh(geo, groundMaterial)
      @ground.position.y -= 10
      @ground.rotation.x = -Math.PI / 2
      @ground.receiveShadow = true

      LW.renderer.scene.add(@ground)

    # Skybox

    path = "/resources/textures/skybox/"
    format = '.jpg'
    urls = [
      path + 'px' + format, path + 'nx' + format
      path + 'py' + format, path + 'ny' + format
      path + 'pz' + format, path + 'nz' + format
    ]

    textureCube = THREE.ImageUtils.loadTextureCube(urls, new THREE.CubeRefractionMapping())
    material = new THREE.MeshBasicMaterial(color: 0xffffff, envMap: textureCube, refractionRatio: 0.95)

    shader = THREE.ShaderLib["cube"]
    shader.uniforms["tCube"].value = textureCube

    material = new THREE.ShaderMaterial({
      fragmentShader: shader.fragmentShader
      vertexShader: shader.vertexShader
      uniforms: shader.uniforms
      side: THREE.BackSide
    })

    mesh = new THREE.Mesh(new THREE.CubeGeometry(10000, 10000, 10000), material)
    LW.renderer.scene.add(mesh)
