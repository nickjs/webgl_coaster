class LW.Renderer
  constructor: ->
    @scene = new THREE.Scene

    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000)

    @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(0xf0f0f0)
    @domElement = @renderer.domElement

    @light = new THREE.PointLight(0xffffff)
    @light.position.set(20, 40, 0)
    @scene.add(@light)

    # cube = new THREE.CubeGeometry(16,8,8)
    # carmat = new THREE.MeshLambertMaterial(color: 0xeeeeee, wireframe: true)
    # @car = new Physijs.BoxMesh(cube, carmat)
    # @carv = new Physijs.Vehicle(@car, new Physijs.VehicleTuning(10.88, 1.83, 0.28, 500, 10.5, 6000))
    # @car.position.set(-30, 9, -50)
    # @scene.add(@carv)

  render: =>
    @renderer.render(@scene, @camera)
    requestAnimationFrame(@render)
