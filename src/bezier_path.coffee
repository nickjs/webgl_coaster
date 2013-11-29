init = (vectors...) ->
  @beziers = []
  i = 0
  while i < vectors.length - 1
    bezier = new THREE.CubicBezierCurve3(vectors[i], vectors[i+1], vectors[i+2], vectors[i+3])
    @beziers.push(bezier)
    i += 3
  return this

getPoint = (t) ->
  if t == 1
    i = @beziers.length - 1
  else
    i = Math.floor(t * @beziers.length)
  bezier = @beziers[i]

  return bezier.getPoint(t * @beziers.length - i)

LW.BezierPath = THREE.Curve.create(init, getPoint)
