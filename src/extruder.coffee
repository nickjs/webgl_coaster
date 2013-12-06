class LW.Extruder extends THREE.Geometry
  constructor: (@spline, options) ->
    super()

    {
      @railRadius, @railDistance, @numberOfRails
      @spineShape, @spineSteps
      @tieShape, @tieDistance, @tieDepth
    } = options

    @drawRail(@railDistance, 0)
    @drawRail(-@railDistance, 0)
    @computeCentroids()
    @computeFaceNormals()
    @computeVertexNormals()

    @drawSpine(@drawTie)
    @computeCentroids()
    @computeFaceNormals()

  drawSpine: (stepCallback) ->
    return unless @spineShape

    splinePoints = @spline.getSpacedPoints(@spineSteps)

    uvgen = THREE.ExtrudeGeometry.WorldUVGenerator

    {tangents, normals, binormals} = LW.FrenetFrames(@spline, @spineSteps, false)
    binormal = new THREE.Vector3
    normal = new THREE.Vector3
    pos2 = new THREE.Vector3

    shapePoints = @spineShape.extractPoints(1)
    vertices = shapePoints.shape

    reverse = !THREE.Shape.Utils.isClockWise(vertices)
    vertices = vertices.reverse() if reverse
    vertexOffset = @vertices.length

    faces = THREE.Shape.Utils.triangulateShape(vertices, [])

    # Stepped Vertices
    # Including front facing
    for s in [0..@spineSteps]
      for vertex in vertices
        normal.copy(normals[s]).multiplyScalar(vertex.x)
        binormal.copy(binormals[s]).multiplyScalar(vertex.y)
        pos2.copy(splinePoints[s]).add(normal).add(binormal)

        @vertices.push(pos2.clone())

    # Lid Faces
    for face in faces
      # Bottom
      @faces.push(new THREE.Face3(face[0] + vertexOffset, face[1] + vertexOffset, face[2] + vertexOffset, null, null, null))
      uvs = uvgen.generateBottomUV(this, @spineShape, null, face[2], face[1], face[0])
      @faceVertexUvs[0].push(uvs)

      # Front
      a = face[0] + vertexOffset + vertices.length * @spineSteps
      b = face[1] + vertexOffset + vertices.length * @spineSteps
      c = face[2] + vertexOffset + vertices.length * @spineSteps
      @faces.push(new THREE.Face3(c, b, a, null, null, null))

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
        a = j + slen1 + vertexOffset
        b = k + slen1 + vertexOffset
        c = k + slen2 + vertexOffset
        d = j + slen2 + vertexOffset

        @faces.push(new THREE.Face3(d, b, a, null, null, null))
        @faces.push(new THREE.Face3(d, c, b, null, null, null))

        uvs = uvgen.generateSideWallUV(this, @spineShape, vertices, null, a, b, c, d, s, @spineSteps, j, k)

        @faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]])
        @faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]])


    for s in [1..@spineSteps]
      stepCallback?(s, tangents, normals, binormals, splinePoints)

    return

  drawTie: (s, tangents, normals, binormals, splinePoints) =>
    return unless @tieShape

    pos2 = new THREE.Vector3
    normal = new THREE.Vector3
    binormal = new THREE.Vector3
    cross = new THREE.Vector3
    vertexOffset = @vertices.length

    @tieVertices ||= @tieShape.extractPoints(1).shape
    @tieFaces ||= THREE.Shape.Utils.triangulateShape(@tieVertices, [])

    n = normals[s]
    bn = binormals[s]
    cross.copy(n).cross(bn).normalize().setLength(@tieDepth / 2).negate()

    for vertex in @tieVertices
      normal.copy(n).multiplyScalar(vertex.x)
      binormal.copy(bn).multiplyScalar(vertex.y)
      pos2.copy(splinePoints[s]).add(normal).add(binormal).add(cross)
      @vertices.push(pos2.clone())

    cross.negate()
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

  drawRail: (xDistance, yDistance) ->
    return unless @numberOfRails

    segments = Math.floor(@spline.getLength())

    {tangents, normals, binormals} = LW.FrenetFrames(@spline, segments)
    pos = pos2 = new THREE.Vector3

    @radialSegments = 8
    grid = []

    for i in [0..segments]
      grid[i] = []

      u = i / segments
      pos = @spline.getPointAt(u)

      tangent = tangents[i]
      normal = normals[i]
      binormal = binormals[i]

      for j in [0..@radialSegments]
        v = j / @radialSegments * 2 * Math.PI
        cx = -@railRadius * Math.cos(v) + xDistance
        cy = @railRadius * Math.sin(v) + yDistance

        pos2.copy( pos );
        pos2.x += cx * normal.x + cy * binormal.x;
        pos2.y += cx * normal.y + cy * binormal.y;
        pos2.z += cx * normal.z + cy * binormal.z;

        grid[i][j] = @vertices.push(pos2.clone()) - 1

    for i in [0..segments - 1]
      for j in [0..@radialSegments]
        ip = i + 1
        jp = (j + 1) % @radialSegments

        a = grid[i][j]
        b = grid[ip][j]
        c = grid[ip][jp]
        d = grid[i][jp]

        uva = new THREE.Vector2(i / segments, j / @radialSegments)
        uvb = new THREE.Vector2((i + 1) / segments, j / @radialSegments)
        uvc = new THREE.Vector2((i + 1) / segments, (j + 1) / @radialSegments)
        uvd = new THREE.Vector2(i / segments, (j + 1) / @radialSegments)

        @faces.push(new THREE.Face3(d, b, a))
        @faceVertexUvs[0].push([uva, uvb, uvd])

        @faces.push(new THREE.Face3(d, c, b))
        @faceVertexUvs[0].push([uvb.clone(), uvc, uvd.clone()])

    return
