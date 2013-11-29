class LW.Renderer
  constructor: ->
    @scene = new Physijs.Scene
    @scene.setGravity(new THREE.Vector3( 0, -30, 0 ))

    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 1000)
    @clock = new THREE.Clock

    @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(0xf0f0f0)
    @domElement = @renderer.domElement

    @light = new THREE.PointLight(0xffffff)
    @light.position.set(20, 40, 0)
    @scene.add(@light)

    @spline = new LW.BezierPath(
      new THREE.Vector3(-40, 0, 0)
      new THREE.Vector3(-40, 0, 0)

      new THREE.Vector3(0, 0, 0)
      new THREE.Vector3(0, 0, 0)
      new THREE.Vector3(10, 0, 0)

      new THREE.Vector3(10, 0, 0)
      new THREE.Vector3(20, 10, 0)
      new THREE.Vector3(30, 20, 0)

      new THREE.Vector3(30, 20, 0)
      new THREE.Vector3(40, 15, 0)
      new THREE.Vector3(45, 12, 0)

      new THREE.Vector3(50, 12, 0)
      new THREE.Vector3(50, 10, 10)
      new THREE.Vector3(45, 10, 20)

      new THREE.Vector3(45, 10, 20)
      new THREE.Vector3(40, 10, 20)
      new THREE.Vector3(20, 10, 20)

      new THREE.Vector3(10, 10, 20)
      new THREE.Vector3(0, 10, 20)
    )

    @track = new LW.BMTrack(@spline)
    @track.position.setZ(-50)
    @track.renderTrack()
    @scene.add(@track)

    # cube = new THREE.CubeGeometry(16,8,8)
    # carmat = new THREE.MeshLambertMaterial(color: 0xeeeeee, wireframe: true)
    # @car = new Physijs.BoxMesh(cube, carmat)
    # @carv = new Physijs.Vehicle(@car, new Physijs.VehicleTuning(10.88, 1.83, 0.28, 500, 10.5, 6000))
    # @car.position.set(-30, 9, -50)
    # @scene.add(@carv)

  render: =>
    LW.controls?.update(@clock.getDelta())

    # @scene.simulate()
    @renderer.render(@scene, @camera)

    requestAnimationFrame(@render)
