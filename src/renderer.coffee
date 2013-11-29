mat = new THREE.MeshLambertMaterial(color: 0xff0000)
wireMat = new THREE.MeshBasicMaterial(color: 0x000000, wireframe: true)

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

    @drawTrack(@spline)

    # cube = new THREE.CubeGeometry(16,8,8)
    # carmat = new THREE.MeshLambertMaterial(color: 0xeeeeee, wireframe: true)
    # @car = new Physijs.BoxMesh(cube, carmat)
    # @carv = new Physijs.Vehicle(@car, new Physijs.VehicleTuning(10.88, 1.83, 0.28, 500, 10.5, 6000))
    # @car.position.set(-30, 9, -50)
    # @scene.add(@carv)

    # wheel = new THREE.CylinderGeometry(1, 1, 1)

    loader = new THREE.JSONLoader();

    loader.load "resources/models/mustang.js", ( car, car_materials ) =>
      loader.load "resources/models/mustang_wheel.js", ( wheel, wheel_materials ) =>
        mesh = new Physijs.BoxMesh(car, new THREE.MeshFaceMaterial(car_materials))
        mesh.position.y = 2;
        # mesh.castShadow = mesh.receiveShadow = true;

        @vehicle = new Physijs.Vehicle(mesh, new Physijs.VehicleTuning(
                10.88,
                1.83,
                0.28,
                500,
                10.5,
                6000
        ));
        @scene.add( @vehicle );

        wheel_material = new THREE.MeshFaceMaterial( wheel_materials );

        for i in [0..3]
          @vehicle.addWheel wheel,
            wheel_material,
            new THREE.Vector3(
                            if i % 2 == 0 then -1.6 else 1.6,
                            -1,
                            if i < 2 then 3.3 else -3.2
            ),
            new THREE.Vector3( 0, -1, 0 ),
            new THREE.Vector3( -1, 0, 0 ),
            0.5,
            1,
            if i < 2 then false else true



  drawTrack: (spline) ->
    @track = new THREE.Object3D
    @track.position.setZ(-50)

    boxSize = 2
    spine = new THREE.Shape
    spine.moveTo(-boxSize, -boxSize)
    spine.lineTo(-boxSize, boxSize)
    spine.lineTo(boxSize, boxSize)
    spine.lineTo(boxSize, -boxSize)
    spine.lineTo(-boxSize, -boxSize)

    radius = 0.5
    offsetX = boxSize + 1.5
    offsetY = boxSize * 2 - 0.5

    rail1 = new THREE.Shape
    rail1.moveTo(offsetX + radius, offsetY)
    rail1.absellipse(offsetX, offsetY, radius, radius, 0, Math.PI*2, false)
    # rail1.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail1.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    offsetX = -boxSize - 1.5

    rail2 = new THREE.Shape
    rail2.moveTo(offsetX + radius, offsetY)
    rail2.absarc(offsetX, offsetY, radius, 0, Math.PI * 2, false)
    # rail2.moveTo(offsetX, offsetY + radius)
    # rail2.quadraticCurveTo(radius + offsetX, radius + offsetY, radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(radius + offsetX, -radius + offsetY, offsetX, -radius + offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, -radius + offsetY, -radius + offsetX, offsetY)
    # rail2.quadraticCurveTo(-radius + offsetX, radius + offsetY, offsetX, radius + offsetY)

    steps = spline.getLength()
    @boxGeo = new THREE.ExtrudeGeometry(spine, {steps: Math.floor(steps / 6), extrudePath: spline})
    spineMesh = new Physijs.ConvexMesh(@boxGeo, mat)
    # spineMesh = THREE.SceneUtils.createMultiMaterialObject(@boxGeo, [mat, wireMat])
    @track.add(spineMesh)

    geo = new THREE.ExtrudeGeometry(rail1, {steps: Math.floor(steps * 6), extrudePath: spline})
    @track.add(THREE.SceneUtils.createMultiMaterialObject(geo, [mat]))

    geo = new THREE.ExtrudeGeometry(rail2, {steps: Math.floor(steps * 6), extrudePath: spline})
    @track.add(THREE.SceneUtils.createMultiMaterialObject(geo, [mat]))

    @track.mat = mat
    @scene.add(@track)

  render: =>
    LW.controls?.update(@clock.getDelta())

    # @vehicle?.applyEngineForce(100)

    # @scene.simulate()
    @renderer.render(@scene, @camera)

    requestAnimationFrame(@render)
