# Some THREE objects don't create their prototype constructor chains correctly
THREE.Mesh::constructor = THREE.Mesh
THREE.CurvePath::constructor = THREE.CurvePath

THREE.Object3D::clear = ->
  child = @children[0]
  while child
    @remove(child)
    child = @children[0]

THREE.Vector4::copy = (v) ->
  @x = v.x
  @y = v.y
  @z = v.z

  if v.w?
    @w = v.w
  if !@w?
    @w = 1

THREE.Vector4::add = (v) ->
  @x += v.x
  @y += v.y
  @z += v.z
  @w += v.w if v.w?

originalLoadTexture = THREE.ImageUtils.loadTexture
THREE.ImageUtils.loadTexture = (url) ->
  components = url.split('/')
  file = components[components.length - 1]
  file = file.split('.')[0]
  return texture if texture = LW.textures[file]
  return originalLoadTexture.call(THREE.ImageUtils, url)

LW.mixin = (context, mixins...) ->
  for mixin in mixins
    if mixin
      for own key, val of mixin
        context[key] = val

  return context

LW.Observable = {
  observe: (key, callback) ->
    @_observers ||= {}
    @_observers[key] ||= []
    @_observers[key].push(callback)

    return this

  forget: (key, callback) ->
    callbacks = @_observers?[key]
    index = callbacks?.indexOf(callback)
    if index? && index != -1
      callbacks.splice(index, 1)

    return this

  fire: (key, value, oldValue) ->
    callbacks = @_observers?[key]
    if callbacks?.length
      for callback in callbacks
        callback(value, oldValue)

    return this
}

LW.UP = new THREE.Vector3(0, 1, 0)
LW.DOWN = new THREE.Vector3(0, -1, 0)

up = LW.UP.clone()
rolledUp = up.clone()
binormal = new THREE.Vector3
tangent = null

LW.getMatrixAt = (spline, u) ->
  tangent = spline.getTangent(u).normalize()

  [bank, relative] = spline.getBankAt(u)
  # bank = spline.getBankAt(u)

  if relative
    binormal.crossVectors(tangent, up).normalize()
    up.crossVectors(binormal, tangent).normalize()
    # FIXME: UP is wrong if we weren't stepping over the entire track
    rolledUp.copy(up).applyAxisAngle(tangent, bank).normalize()
    binormal.crossVectors(tangent, rolledUp).normalize()
  else
    up.copy(LW.UP).applyAxisAngle(tangent, bank)

  binormal.crossVectors(tangent, up).normalize()
  up.crossVectors(binormal, tangent).normalize()
  rolledUp.copy(up)

  return new THREE.Matrix4(binormal.x, rolledUp.x, -tangent.x, 0,
                           binormal.y, rolledUp.y, -tangent.y, 0,
                           binormal.z, rolledUp.z, -tangent.z, 0,
                           0, 0, 0, 1)

appliedOffset = new THREE.Vector3

LW.positionObjectOnSpline = (object, spline, u, offset, offsetRotation) ->
  pos = spline.getPoint(u)
  matrix = @getMatrixAt(spline, u)

  object.position.copy(pos)

  if offset
    appliedOffset.copy(offset)
    object.position.add(appliedOffset.applyMatrix4(matrix))

  if offsetRotation
    matrix.multiply(offsetRotation)

  object.rotation.setFromRotationMatrix(matrix)
  return tangent
