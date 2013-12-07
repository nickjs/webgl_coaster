class LW.Renderer
  constructor: ->
    @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(0xf0f0f0)
    @renderer.autoClear = false
    @domElement = @renderer.domElement

    @scene = new THREE.Scene
    @clock = new THREE.Clock()

    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000)
    @camera.shouldRotate = true
    @camera.position.z += 60

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
    # @frontCamera.position.y += 1
    @frontCamera.lookAt(new THREE.Vector3(0, 0, -1))
    @scene.add(@frontCamera)

    @sideCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000)
    @sideCamera.zoom = zoom
    # @sideCamera.position.y += 1
    @sideCamera.lookAt(new THREE.Vector3(1, 0, 0))
    @scene.add(@sideCamera)

    @light = new THREE.PointLight(0xffffff)
    @light.position.set(20, 40, 0)
    @scene.add(@light)

  render: =>
    LW.train?.simulate(@clock.getDelta())

    SCREEN_WIDTH = window.innerWidth * @renderer.devicePixelRatio
    SCREEN_HEIGHT = window.innerHeight * @renderer.devicePixelRatio

    @renderer.clear()

    LW.track.material.wireframe = true

    @renderer.setViewport(1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
    @renderer.render(@scene, @topCamera)

    @renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2)
    @renderer.render(@scene, @sideCamera)

    @renderer.setViewport( 1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2 )
    @renderer.render(@scene, @frontCamera)
    LW.track.material.wireframe = LW.track.forceWireframe || false

    @renderer.setViewport( 0.5 * SCREEN_WIDTH + 1, 1,   0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2 )
    @renderer.render(@scene, @camera)

    requestAnimationFrame(@render)
