init = (vectors...) ->
  @vectors = vectors
  @count = Math.floor(vectors.length / 3) - 1

getPoint = (t) ->
  if t == 1
    i = @count - 1
  else if t == 0
    i = 0
  else
    i = Math.floor(t * @count)

  index = i * 3
  bezier = new THREE.CubicBezierCurve3(@vectors[index + 1], @vectors[index + 2], @vectors[index + 3], @vectors[index + 4])

  return bezier.getPoint(t * @count - i)

LW.BezierPath = THREE.Curve.create(init, getPoint)

LW.BezierPath::addControlPoint = (pos) ->
  last = @vectors[@vectors.length - 2]

  @vectors.push(pos.clone().add(new THREE.Vector3(-10, 0, 0)))
  @vectors.push(pos.clone())
  @vectors.push(pos.clone().add(new THREE.Vector3(10, 0, 0)))

  @count++
  @needsUpdate = true
