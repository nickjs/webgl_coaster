#= require_self
#= require bezier_path
#= require spline
#= require renderer
#= require terrain

#= require edit_track
#= require bm_track


Physijs.scripts.worker = '/assets/physijs_worker.js'
Physijs.scripts.ammo = '/assets/ammo.js'

window.LW =
  init: ->
    renderer = @renderer = new LW.Renderer
    document.body.appendChild(renderer.domElement)

    terrain = new LW.Terrain(renderer)

    controls = @controls = new THREE.OrbitControls(renderer.camera, renderer.domElement)
    controls.target = renderer.track.position.clone()

    renderer.render()

    gui = new dat.GUI()
    trackFolder = gui.addFolder('Track')
    trackFolder.open()

    if renderer.track.material
      trackFolder.addColor(color: "#ff0000", 'color').onChange (value) -> renderer.track.material.color.setHex(value.replace('#', '0x'))
      trackFolder.add(renderer.spline.beziers[0].v0, 'x', -100, 0).onChange (value) -> renderer.scene.remove(renderer.track); renderer.drawTrack(renderer.spline)
      trackFolder.add(renderer.track.material, 'wireframe')

    pos = trackFolder.addFolder('Position')
    pos.add(renderer.track.position, 'x', -100, 100)
    pos.add(renderer.track.position, 'y', -100, 100)
    pos.add(renderer.track.position, 'z', -100, 100)

    rot = trackFolder.addFolder('Rotation')
    rot.add(renderer.track.rotation, 'x', 0, Math.PI * 2)
    rot.add(renderer.track.rotation, 'y', 0, Math.PI * 2).step(0.05)
    rot.add(renderer.track.rotation, 'z', 0, Math.PI * 2)
    rot.open()

window.onload = -> LW.init()
