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

LW.mixin = (context, mixin) ->
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
normal = new THREE.Vector3
binormal = new THREE.Vector3
appliedOffset = new THREE.Vector3
matrix = new THREE.Matrix4

LW.positionObjectOnSpline = (object, spline, u, offset, offsetRotation) ->
  pos = spline.getPointAt(u)
  tangent = spline.getTangentAt(u).normalize()

  bank = THREE.Math.degToRad(@model.getBankAt(u))
  binormal.copy(LW.UP).applyAxisAngle(tangent, bank)

  normal.crossVectors(tangent, binormal).normalize()
  binormal.crossVectors(normal, tangent).normalize()

  matrix.set(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1)

  object.position.copy(pos)

  if offset
    appliedOffset.copy(offset)
    object.position.add(appliedOffset.applyMatrix4(matrix))

  if offsetRotation
    matrix.multiply(offsetRotation)

  object.rotation.setFromRotationMatrix(matrix)
  return tangent
