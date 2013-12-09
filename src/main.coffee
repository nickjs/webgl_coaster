#= require_self
#= require bezier_path
#= require spline
#= require renderer
#= require terrain
#= require track
#= require train

#= require edit_track
#= require bm_track

# Some THREE objects don't create their prototype constructor chains correctly
THREE.Mesh::constructor = THREE.Mesh
THREE.CurvePath::constructor = THREE.CurvePath

THREE.Object3D::clear = ->
    child = @children[0]
    while child
      @remove(child)
      child = @children[0]

window.LW =
  init: ->
    renderer = @renderer = new LW.Renderer
    document.body.appendChild(renderer.domElement)

    terrain = new LW.Terrain(renderer)

    if json = localStorage.getItem('track')
      @spline = LW.BezierPath.fromJSON(JSON.parse(json))
    else
      @spline = new LW.BezierPath([
        new THREE.Vector3(-10, 0, 0)
        new THREE.Vector3(-40, 0, 0)
        new THREE.Vector3(10, 0, 0)

        new THREE.Vector3(-10, -20, 0)
        new THREE.Vector3(0, 18, 0)
        new THREE.Vector3(10, 20, 0)

        new THREE.Vector3(-14, -10, -40)
        new THREE.Vector3(47, 20, 40).setBank(60)
        new THREE.Vector3(14, 10, 40)

        new THREE.Vector3(30, 0, 0)
        new THREE.Vector3(0, 0, 80).setBank(20)
        new THREE.Vector3(-30, 0, 0)

        new THREE.Vector3(18, 0, 0)
        new THREE.Vector3(-80, 0, 80).setBank(-359)
        new THREE.Vector3(-18, 0, 0)

        new THREE.Vector3(2.5, 0, 23)
        new THREE.Vector3(-120, 0, 40).setBank(-359)
        new THREE.Vector3(-2.5, 0, -23)

        new THREE.Vector3(-33, 0, 0)
        new THREE.Vector3(-80, 0, 0).setBank(-359)
        new THREE.Vector3(33, 0, 0)
      ])

    @edit = new LW.EditTrack(@spline)
    @edit.renderTrack()
    renderer.scene.add(@edit)

    @track = new LW.BMTrack(@spline)
    @track.renderRails = true
    @track.forceWireframe = false
    @track.rebuild()
    renderer.scene.add(@track)

    @train = new LW.Train(numberOfCars: 2)
    @train.attachToTrack(@track)
    renderer.scene.add(@train)

    controls = @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    controls.center.copy(@edit.position)
    controls.addEventListener 'change', =>
      @edit?.transformControl?.update()

    renderer.render()

    @gui = new dat.GUI()
    @gui.add(@renderer, 'useQuadView')
    @trackFolder = @gui.addFolder('Track')
    @trackFolder.open()

    @trackFolder.addColor(spineColor: "#ff0000", 'spineColor').onChange (value) => @track.spineMaterial.color.setHex(value.replace('#', '0x'))
    @trackFolder.addColor(tieColor: "#ff0000", 'tieColor').onChange (value) => @track.tieMaterial.color.setHex(value.replace('#', '0x'))
    @trackFolder.addColor(railColor: "#ff0000", 'railColor').onChange (value) => @track.railMaterial.color.setHex(value.replace('#', '0x'))
    @trackFolder.add(@track, 'forceWireframe')
    @trackFolder.add(@edit, 'debugNormals').onChange => @edit.renderCurve()
    @trackFolder.add(@track, 'renderRails').onChange => @track.renderTrack()
    @trackFolder.add(@spline, 'isConnected').onChange (value) =>
      if value then @spline.connect() else @spline.disconnect()
      @edit.changed(true)

    @trackFolder.add({addPoint: =>
      @spline.addControlPoint(@spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)))
      @edit.renderTrack()
      @track.renderTrack()

      @edit.selectNode()
    }, 'addPoint')

    @onRideCamera = false
    @trainFolder = @gui.addFolder('Train')
    @trainFolder.open()

    @trainFolder.addColor(color: '#ffffff', 'color').onChange (value) => @train.carMaterial.color.setHex(value.replace('#', '0x'))
    @trainFolder.add(@train, 'movementSpeed', 0.01, 0.1)
    @trainFolder.add(@train, 'numberOfCars', 0, 8).step(1).onChange (value) => @train.rebuild()
    @trainFolder.add(this, 'onRideCamera').onChange (value) =>
      if value
        @oldCamPos = @renderer.camera.position.clone()
        @oldCamRot = @renderer.camera.rotation.clone()
        LW.renderer.scene.remove(@edit)
      else
        @renderer.camera.position.copy(@oldCamPos)
        @renderer.camera.rotation.copy(@oldCamRot)
        LW.renderer.scene.add(@edit)

    @selected = {x: 0, y: 0, z: 0, bank: 0}
    updateVector = (index, value) =>
      return if not @selected.node
      @selected.node.position[index] = value
      @selected.node.splineVector[index] = value
      @edit.changed(true)

    @pointFolder = @gui.addFolder('Point')
    @pointFolder.add(@selected, 'x').onChange (value) -> updateVector('x', value)
    @pointFolder.add(@selected, 'y').onChange (value) -> updateVector('y', value)
    @pointFolder.add(@selected, 'z').onChange (value) -> updateVector('z', value)
    @pointFolder.add(@selected, 'bank').onChange (value) -> updateVector('bank', value)

  selectionChanged: (selected) ->
    if selected
      @selected.x = selected.splineVector.x
      @selected.y = selected.splineVector.y
      @selected.z = selected.splineVector.z
      @selected.bank = selected.splineVector.bank || 0
      @selected.node = selected

      for controller in @pointFolder.__controllers
        controller.updateDisplay()

      @pointFolder.open()

    else
      @pointFolder.close()

window.onload = -> LW.init()
