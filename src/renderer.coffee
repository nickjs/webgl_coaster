class LW.Renderer
  showFPS: true
  useQuadView: false

  constructor: (container) ->
    @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(0xf0f0f0)
    @renderer.autoClear = false

    @renderer.gammaInput = true
    @renderer.gammaOutput = true
    @renderer.physicallyBasedShading = true

    @renderer.shadowMapEnabled = true
    @renderer.shadowMapType = THREE.PCFSoftShadowMap

    @domElement = @renderer.domElement
    container.appendChild(@domElement)

    @stats = new Stats if Stats?
    container.appendChild(@stats.domElement) if @stats && @showFPS

    @scene = new THREE.Scene
    @clock = new THREE.Clock

    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000)

    hemiLight = new THREE.HemisphereLight(0xffffff, 0xffffff, 0.6)
    hemiLight.color.setHSL(0.58, 0.1, 0.7)
    hemiLight.groundColor.setHSL(0.24, 0.1, 0.7)
    hemiLight.position.set(0, 1000, 0)
    @scene.add(hemiLight)

    @dirLight = new THREE.DirectionalLight(0xffffff, 0.8)
    @dirLight.position.set(-1000, 1000, 1000)
    # @dirLight.shadowCameraVisible = true
    @dirLight.castShadow = true
    @dirLight.shadowMapWidth = 4096
    @dirLight.shadowMapHeight = 4096
    @scene.add(@dirLight)

    d = 2000
    @dirLight.shadowCameraLeft = -d
    @dirLight.shadowCameraRight = d
    @dirLight.shadowCameraTop = d
    @dirLight.shadowCameraBottom = -d

    @audioContext = new AudioContext

    window.addEventListener('resize', @onResize, false)

  render: =>
    return if @killed

    @renderer.clear()

    delta = @clock.getDelta()
    LW.train?.update(delta)
    LW.controls?.update(delta)
    LW.terrain?.update?(delta)

    mainCamera = LW.train?.camera if LW.model?.onRideCamera
    mainCamera ||= @camera

    @renderer.render(@scene, mainCamera)
    @stats?.update()

    requestAnimationFrame(@render)

  onResize: =>
    SCREEN_WIDTH = window.innerWidth * @renderer.devicePixelRatio
    SCREEN_HEIGHT = window.innerHeight * @renderer.devicePixelRatio

    @renderer.setSize(window.innerWidth, window.innerHeight)

    for camera in [@camera, LW.train?.camera]
      continue if not camera

      camera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT
      camera.updateProjectionMatrix()

  kill: ->
    @renderer = null
    @killed = true
