class LW.Renderer
  showFPS: true
  useQuadView: false

  defaultCamPos: new THREE.Vector3(0, 0, 60)
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

    @stats = new Stats
    container.appendChild(@stats.domElement) if @showFPS

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
    @scene.add(@topCamera)

    @frontCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @frontCamera.zoom = zoom
    @frontCamera.lookAt(new THREE.Vector3(0, 0, -1))
    @scene.add(@frontCamera)

    @sideCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @sideCamera.zoom = zoom
    @sideCamera.lookAt(new THREE.Vector3(1, 0, 0))
    @scene.add(@sideCamera)

    @light = new THREE.DirectionalLight(0xffffff, 0.8)
    @light.position.set(0, 1000, 0)
    @light.castShadow = true
    @light.shadowMapWidth = 4096
    @light.shadowMapHeight = 4096
    @scene.add(@light)

    @bottomLight = new THREE.DirectionalLight(0xffffff, 0.5)
    @bottomLight.position.set(0, -1, 0)
    @scene.add(@bottomLight)

    sideLight = new THREE.DirectionalLight(0xffffff, 0.3)
    sideLight.position.set(0, 0, -1)
    @scene.add(sideLight)

    sideLight = new THREE.DirectionalLight(0xffffff, 0.3)
    sideLight.position.set(0, 0, 1)
    @scene.add(sideLight)

  render: =>
    LW.train?.simulate(@clock.getDelta())

    SCREEN_WIDTH = window.innerWidth * @renderer.devicePixelRatio
    SCREEN_HEIGHT = window.innerHeight * @renderer.devicePixelRatio

    @renderer.clear()

    if @useQuadView
      @renderer.setViewport(1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @topCamera)

      @renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @sideCamera)

      @renderer.setViewport(1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
      @renderer.render(@scene, @frontCamera)

      @renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
    else
      @renderer.setViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    mainCamera = LW.train?.camera if LW.model?.onRideCamera
    mainCamera ||= @camera

    @renderer.render(@scene, mainCamera)

    @stats.update()

    requestAnimationFrame(@render)
