class LW.EditTrack extends THREE.Object3D
  constructor: (@spline) ->
    super()

  renderTrack: ->
    for curve, i in @spline.beziers
      @renderBezier(curve, i > 0)

  renderBezier: (curve, skipFirst) ->
    for i in [0..3]
      continue if i == 0 and skipFirst

      geo = new THREE.SphereGeometry(1)
      mat = new THREE.MeshLambertMaterial(color: if i in [0, 3] then 0x0000ee else 0x00ee00)
      mesh = new THREE.Mesh(geo, mat)
      mesh.position.copy(curve["v#{i}"])
      @add(mesh)
