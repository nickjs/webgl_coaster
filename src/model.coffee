colladaLoader = (definition, parser) ->
  loader = new THREE.ColladaLoader
  callbacks = []
  geometry = null

  loader.onLoad = (callback) ->
    callbacks.push(callback)
    callback(geometry.clone()) if geometry

  loader.load definition.path, (result) ->
    if definition.onlyMeshes
      meshes = []
      result.scene.traverse (child) ->
        if child instanceof THREE.Mesh
          child.material?.transparent = true if definition.transparent
          meshes.push(child)

      geometry = new THREE.Object3D
      geometry.add(child) for child in meshes
    else
      geometry = result.scene.children[0]

    parser?(geometry)

    for callback in callbacks
      callback(geometry.clone())

  return loader

class LW.Model extends THREE.Object3D
  constructor: (@definition, parser) ->
    super

    if loader = definition._loader
      loader.onLoad(@onLoad)
    else
      @load(parser)

  load: (parser) ->
    loader = colladaLoader(@definition, parser)
    loader.onLoad(@onLoad)

    @definition._loader = loader

  onLoad: (@geometry) =>
    info = @definition
    geometry.position.set(0, 0, 0)
    geometry.position.copy(info.position) if info.position

    geometry.scale.copy(info.scale) if info.scale instanceof THREE.Vector3
    geometry.scale.set(info.scale, info.scale, info.scale) if typeof info.scale == 'number'

    geometry.rotation.copy(info.rotation) if info.rotation

    @add(geometry)
