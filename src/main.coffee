#= require_self
#= require bezier_path
#= require extruder
#= require frenet
#= require spline
#= require renderer
#= require terrain

#= require edit_track
#= require bm_track

# Some THREE objects don't create their prototype constructor chains correctly
THREE.Mesh::constructor = THREE.Mesh
THREE.Object3D::clear = ->
    child = @children[0]
    while child
      @remove(child)
      child = @children[0]

Physijs.scripts.worker = '/assets/physijs_worker.js'
Physijs.scripts.ammo = '/assets/ammo.js'

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

        new THREE.Vector3(-14, -10, -20)
        new THREE.Vector3(47, 20, 20)
        new THREE.Vector3(14, 10, 20)
      ])

    @edit = new LW.EditTrack(@spline)
    @edit.position.set(0, 3, -50)
    @edit.renderTrack()
    renderer.scene.add(@edit)

    @track = new LW.BMTrack(@spline)
    @track.position.set(0, 3, -50)
    @track.renderRails = true
    @track.forceWireframe = false
    @track.renderTrack()
    renderer.scene.add(@track)

    controls = @controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement)
    controls.center.copy(@edit.position)
    controls.addEventListener 'change', =>
      @edit?.transformControl?.update()

    renderer.render()

    @gui = new dat.GUI()
    @trackFolder = @gui.addFolder('Track')
    @trackFolder.open()

    @trackFolder.addColor(color: "#ff0000", 'color').onChange (value) => @track.material.color.setHex(value.replace('#', '0x'))
    @trackFolder.add(@track, 'forceWireframe')
    @trackFolder.add(@track, 'renderRails').onChange -> LW.track.renderTrack()

    @trackFolder.add({addPoint: =>
      @spline.addControlPoint(@spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)))
      @edit.renderTrack()
      @track.renderTrack()

      @edit.selectNode()
    }, 'addPoint')

    @selected = {x: 0, y: 0, z: 0, bank: 0}
    @pointFolder = @gui.addFolder('Point')
    @pointFolder.add(@selected, 'x').onChange (value) => @selected.node.position.x = value; @edit.changed()
    @pointFolder.add(@selected, 'y').onChange (value) => @selected.node.position.y = value; @edit.changed()
    @pointFolder.add(@selected, 'z').onChange (value) => @selected.node.position.z = value; @edit.changed()
    @pointFolder.add(@selected, 'bank').onChange (value) => @selected.node.position.bank = value; @edit.changed()

    @edit.selectNode()

  selectionChanged: (selected) ->
    if selected
      @selected.x = selected.position.x
      @selected.y = selected.position.y
      @selected.z = selected.position.z
      @selected.bank = selected.position.bank || 0
      @selected.node = selected

      for controller in @pointFolder.__controllers
        controller.updateDisplay()

      @pointFolder.open()

    else
      @pointFolder.close()

window.onload = -> LW.init()
