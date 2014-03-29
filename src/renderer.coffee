class LW.Renderer
  showFPS: true
  useQuadView: false

  defaultCamPos: new THREE.Vector3(0, 20, 60)
  defaultCamRot: new THREE.Euler(0, 0, 0, 'XYZ')

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
    @camera.shouldRotate = true
    @camera.position.copy(@defaultCamPos)
    @camera.rotation.copy(@defaultCamRot)

    zoom = 16
    x = window.innerWidth / zoom
    y = window.innerHeight / zoom

    @topCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @topCamera.zoom = zoom
    @topCamera.up = new THREE.Vector3(0, 0, -1)
    @topCamera.lookAt(new THREE.Vector3(0, -1, 0))

    @frontCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @frontCamera.zoom = zoom
    @frontCamera.lookAt(new THREE.Vector3(0, 0, -1))

    @sideCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @sideCamera.zoom = zoom
    @sideCamera.lookAt(new THREE.Vector3(1, 0, 0))

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

    window.addEventListener('resize', @onResize, false)

  render: =>
    return if @killed

    @renderer.clear()

    delta = @clock.getDelta()
    LW.train?.update(delta)
    LW.controls?.update?(delta)
    LW.terrain?.update?(delta)

    SCREEN_WIDTH = window.innerWidth
    SCREEN_HEIGHT = window.innerHeight

    if @useQuadView
      @renderer.setViewport(1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @topCamera)

      @renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @sideCamera)

      @renderer.setViewport(1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @frontCamera)

      @renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
    else
      @renderer.setViewport(0.0, 0.0, SCREEN_WIDTH, SCREEN_HEIGHT)

    mainCamera = LW.train?.camera if LW.model?.onRideCamera
    mainCamera ||= @camera

    @renderer.render(@scene, mainCamera)
    @stats?.update()

    requestAnimationFrame(@render)

  onResize: =>
    SCREEN_WIDTH = window.innerWidth * @renderer.devicePixelRatio
    SCREEN_HEIGHT = window.innerHeight * @renderer.devicePixelRatio

    @renderer.setSize(window.innerWidth, window.innerHeight)

    for camera in [@camera, @topCamera, @sideCamera, @frontCamera, LW.train?.camera]
      continue if not camera

      camera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT
      camera.updateProjectionMatrix()

  kill: ->
    @renderer = null
    @killed = true
