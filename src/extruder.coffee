class LW.Extruder extends THREE.Geometry
  constructor: (@spline, options) ->
    super()

    {
      @railRadius, @railDistance, @numberOfRails
      @spineShape, @spineSteps
      @tieShape, @tieDistance, @tieDepth
    } = options

    @drawSpine(@drawTie)
    @computeCentroids()
    @computeFaceNormals()

  drawSpine: (stepCallback) ->
    return unless @spineShape

    splinePoints = @spline.getSpacedPoints(@spineSteps)

    uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

    frames = new THREE.TubeGeometry.FrenetFrames(@spline, @spineSteps, false)
    binormal = new THREE.Vector3
    normal = new THREE.Vector3
    pos2 = new THREE.Vector3

    shapePoints = @spineShape.extractPoints(1)
    vertices = shapePoints.shape

    reverse = !THREE.Shape.Utils.isClockWise(vertices)
    vertices = vertices.reverse() if reverse

    faces = THREE.Shape.Utils.triangulateShape(vertices, [])

    # Stepped Vertices
    # Including front facing
    for s in [0..@spineSteps]
      for vertex in vertices
        normal.copy(frames.normals[s]).multiplyScalar(vertex.x)
        binormal.copy(frames.binormals[s]).multiplyScalar(vertex.y)
        pos2.copy(splinePoints[s]).add(normal).add(binormal)

        @vertices.push(pos2.clone())

    # Lid Faces
    for face in faces
      # Bottom
      @faces.push(new THREE.Face3(face[2], face[1], face[0], null, null, null))
      uvs = uvgen.generateBottomUV(this, @spineShape, null, face[2], face[1], face[0])
      @faceVertexUvs[0].push(uvs)

      # Front
      a = face[0] + vertices.length * @spineSteps
      b = face[1] + vertices.length * @spineSteps
      c = face[2] + vertices.length * @spineSteps
      @faces.push(new THREE.Face3(a, b, c, null, null, null))

      uvs = uvgen.generateTopUV(this, @spineShape, null, a, b, c)
      @faceVertexUvs[0].push(uvs)

    # Side Faces
    i = vertices.length
    while --i >= 0
      j = i
      k = i - 1
      k = vertices.length - 1 if k < 0

      for s in [0..@spineSteps - 1]
        slen1 = vertices.length * s
        slen2 = vertices.length * (s + 1)
        a = j + slen1
        b = k + slen1
        c = k + slen2
        d = j + slen2

        @faces.push(new THREE.Face3(a, b, d, null, null, null))
        @faces.push(new THREE.Face3(b, c, d, null, null, null))

        uvs = uvgen.generateSideWallUV(this, @spineShape, vertices, null, a, b, c, d, s, @spineSteps, j, k)

        @faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        @faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])


    for s in [1..@spineSteps]
      stepCallback?(s, frames, splinePoints)

    return

  drawTie: (s, frames, splinePoints) =>
    return unless @tieShape

    pos2 = new THREE.Vector3
    normal = new THREE.Vector3
    binormal = new THREE.Vector3
    cross = new THREE.Vector3
    vertexOffset = @vertices.length

    @tieVertices ||= @tieShape.extractPoints(1).shape
    @tieFaces ||= THREE.Shape.Utils.triangulateShape(@tieVertices, [])

    n = frames.normals[s]
    bn = frames.binormals[s]
    cross.copy(n).cross(bn).normalize().setLength(0.65)

    for vertex in @tieVertices
      normal.copy(n).multiplyScalar(vertex.x)
      binormal.copy(bn).multiplyScalar(vertex.y)
      pos2.copy(splinePoints[s]).add(normal).add(binormal)
      @vertices.push(pos2.clone())

    for vertex in @tieVertices
      normal.copy(n).multiplyScalar(vertex.x)
      binormal.copy(bn).multiplyScalar(vertex.y)
      pos2.copy(splinePoints[s]).add(normal).add(binormal).add(cross)
      @vertices.push(pos2.clone())

    for face in @tieFaces
      @faces.push(new THREE.Face3(face[2] + vertexOffset, face[1] + vertexOffset, face[0] + vertexOffset, null, null, null))

      a = face[0] + vertexOffset + @tieVertices.length
      b = face[1] + vertexOffset + @tieVertices.length
      c = face[2] + vertexOffset + @tieVertices.length
      @faces.push(new THREE.Face3(a, b, c, null, null, null))

    i = @tieVertices.length
    while --i >= 0
      j = i
      k = i - 1
      k = @tieVertices.length - 1 if k < 0

      slen1 = @tieVertices.length
      slen2 = 0
      a = j + slen1 + vertexOffset
      b = k + slen1 + vertexOffset
      c = k + slen2 + vertexOffset
      d = j + slen2 + vertexOffset

      @faces.push(new THREE.Face3(a, b, d, null, null, null))
      @faces.push(new THREE.Face3(b, c, d, null, null, null))

    return
