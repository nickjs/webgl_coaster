LW.FrenetFrames = (path, segments) ->
  tangents = []
  normals = []
  binormals = []

  up = new THREE.Vector3(0, 1, 0)

  # compute the tangent vectors for each segment on the path
  for i in [0..segments]
    u = i / (segments)

    tangents[i] = path.getTangentAt(u).normalize()

    binormals[ i ] = up.clone().applyAxisAngle(tangents[i], 0)

    normals[ i ] = tangents[i].clone().cross(binormals[i]).normalize()

    binormals[ i ] = normals[i].clone().cross(tangents[i]).normalize()

  return {tangents, normals, binormals}
