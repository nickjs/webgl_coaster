init = (@vectors) ->
  @count = Math.floor(vectors.length / 3) - 1

getPoint = (t) ->
  if t == 1
    i = @count - 1
  else if t == 0
    i = 0
  else
    i = Math.floor(t * @count)

  index = i * 3

  leftCP = @vectors[index + 1]
  rightCP = @vectors[index + 4]
  leftHandle = @vectors[index + 2].clone().add(leftCP)
  rightHandle = @vectors[index + 3].clone().add(rightCP)

  bezier = new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP)
  return bezier.getPoint(t * @count - i)

LW.BezierPath = THREE.Curve.create(init, getPoint)

LW.BezierPath::getBankAt = (t) ->
  if t == 1
    i = @count - 1
  else if t == 0
    i = 0
  else
    i = Math.floor(t * @count)

  index = i * 3

  return @vectors[index + 4].bank || 0

LW.BezierPath::addControlPoint = (pos) ->
  last = @vectors[@vectors.length - 2]

  @vectors.push(new THREE.Vector3(-10, 0, 0))
  @vectors.push(pos.clone())
  @vectors.push(new THREE.Vector3(10, 0, 0))

  @count++
  @needsUpdate = true

LW.BezierPath.fromJSON = (vectorJSON) ->
  vectors = for v in vectorJSON
    new THREE.Vector3().fromArray(v)
  return new LW.BezierPath(vectors)

LW.BezierPath::toJSON = ->
  for vector in @vectors
    vector.toJSON()

THREE.Vector3::toJSON = ->
  [@x, @y, @z]

THREE.Vector3::setBank = (amount) ->
  @bank = amount
