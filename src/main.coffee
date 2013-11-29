#= require_self
#= require bezier_path
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

    @spline = new LW.BezierPath(
      new THREE.Vector3(-50, 0, 0)
      new THREE.Vector3(-40, 0, 0)
      new THREE.Vector3(-30, 0, 0)

      new THREE.Vector3(-10, 0, 0)
      new THREE.Vector3(0, 0, 0)
      new THREE.Vector3(12, 0, 0)

      new THREE.Vector3(10, 0, 0)
      new THREE.Vector3(20, 10, 0)
      new THREE.Vector3(30, 20, 0)

      new THREE.Vector3(30, 21, 0)
      new THREE.Vector3(40, 15, 0)
      new THREE.Vector3(45, 12, 0)

      new THREE.Vector3(50, 12, 0)
      new THREE.Vector3(50, 10, 10)
      new THREE.Vector3(45, 10, 20)

      new THREE.Vector3(45, 12, 20)
      new THREE.Vector3(40, 10, 20)
      new THREE.Vector3(20, 10, 20)

      new THREE.Vector3(10, 10, 20)
      new THREE.Vector3(0, 10, 20)
      new THREE.Vector3(-10, 10, 20)
    )

    @edit = new LW.EditTrack(@spline)
    @edit.position.set(0, 3, -50)
    @edit.renderTrack()
    renderer.scene.add(@edit)

    @track = new LW.BMTrack(@spline)
    @track.position.set(0, 3, -50)
    @track.renderRails = false
    @track.renderTrack()
    renderer.scene.add(@track)

    controls = @controls = new THREE.OrbitControls(renderer.camera, renderer.domElement)
    controls.target = @edit.position.clone()

    renderer.render()

    gui = new dat.GUI()
    trackFolder = gui.addFolder('Track')
    trackFolder.open()

    if @track?.material
      trackFolder.addColor(color: "#ff0000", 'color').onChange (value) => @track.material.color.setHex(value.replace('#', '0x'))
      # trackFolder.add(renderer.spline.beziers[0].v0, 'x', -100, 0).onChange (value) -> renderer.scene.remove(@track); renderer.drawTrack(renderer.spline)
      trackFolder.add(@track.material, 'wireframe')
      trackFolder.add(@track, 'renderRails').onChange -> LW.track.renderTrack()

      trackFolder.add({addPoint: =>
        @spline.addControlPoint(@spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)))
        @edit.renderTrack()
        @track.renderTrack()

        @edit.selectNode()
      }, 'addPoint')

    if @track
      pos = trackFolder.addFolder('Position')
      pos.add(@track.position, 'x', -100, 100)
      pos.add(@track.position, 'y', -100, 100)
      pos.add(@track.position, 'z', -100, 100)

      rot = trackFolder.addFolder('Rotation')
      rot.add(@track.rotation, 'x', 0, Math.PI * 2)
      rot.add(@track.rotation, 'y', 0, Math.PI * 2).step(0.05)
      rot.add(@track.rotation, 'z', 0, Math.PI * 2)
      rot.open()

window.onload = -> LW.init()
