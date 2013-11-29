class LW.Terrain
  constructor: (renderer) ->
    geo = new THREE.PlaneGeometry(1000, 1000, 125, 125)

    groundMaterial = new THREE.MeshPhongMaterial(color: 0xffffff, specular: 0x111111)
    groundTexture = THREE.ImageUtils.loadTexture "resources/textures/grass.jpg", undefined, ->
      groundMaterial.map = groundTexture
      groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
      groundTexture.repeat.set(25, 25)
      groundTexture.anisotropy = 16;

      @ground = new Physijs.HeightfieldMesh(geo, groundMaterial)
      @ground.position.y -= 5
      @ground.rotation.x = -Math.PI / 2
      renderer.scene.add(@ground)

  render: ->
