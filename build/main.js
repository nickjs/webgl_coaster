THREE.Mesh.prototype.constructor = THREE.Mesh;

THREE.CurvePath.prototype.constructor = THREE.CurvePath;

THREE.Object3D.prototype.clear = function() {
  var child, _results;
  child = this.children[0];
  _results = [];
  while (child) {
    this.remove(child);
    _results.push(child = this.children[0]);
  }
  return _results;
};

window.LW = {
  init: function() {
    var controls, json, renderer, terrain, updateVector,
      _this = this;
    renderer = this.renderer = new LW.Renderer;
    document.body.appendChild(renderer.domElement);
    terrain = new LW.Terrain(renderer);
    if (json = localStorage.getItem('track')) {
      this.spline = LW.BezierPath.fromJSON(JSON.parse(json));
    } else {
      this.spline = new LW.BezierPath([new THREE.Vector3(-10, 0, 0), new THREE.Vector3(-40, 0, 0), new THREE.Vector3(10, 0, 0), new THREE.Vector3(-10, -20, 0), new THREE.Vector3(0, 18, 0), new THREE.Vector3(10, 20, 0), new THREE.Vector3(-14, -10, -40), new THREE.Vector3(47, 20, 40).setBank(60), new THREE.Vector3(14, 10, 40), new THREE.Vector3(30, 0, 0), new THREE.Vector3(0, 0, 80).setBank(20), new THREE.Vector3(-30, 0, 0), new THREE.Vector3(18, 0, 0), new THREE.Vector3(-80, 0, 80).setBank(-359), new THREE.Vector3(-18, 0, 0), new THREE.Vector3(2.5, 0, 23), new THREE.Vector3(-120, 0, 40).setBank(-359), new THREE.Vector3(-2.5, 0, -23), new THREE.Vector3(-33, 0, 0), new THREE.Vector3(-80, 0, 0).setBank(-359), new THREE.Vector3(33, 0, 0)]);
    }
    this.edit = new LW.EditTrack(this.spline);
    this.edit.renderTrack();
    renderer.scene.add(this.edit);
    this.track = new LW.BMTrack(this.spline);
    this.track.renderRails = true;
    this.track.forceWireframe = false;
    this.track.renderTrack();
    renderer.scene.add(this.track);
    this.train = new LW.Train({
      numberOfCars: 2
    });
    this.train.attachToTrack(this.track);
    renderer.scene.add(this.train);
    controls = this.controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement);
    controls.center.copy(this.edit.position);
    controls.addEventListener('change', function() {
      var _ref, _ref1;
      return (_ref = _this.edit) != null ? (_ref1 = _ref.transformControl) != null ? _ref1.update() : void 0 : void 0;
    });
    renderer.render();
    this.gui = new dat.GUI();
    this.trackFolder = this.gui.addFolder('Track');
    this.trackFolder.open();
    this.trackFolder.addColor({
      color: "#ff0000"
    }, 'color').onChange(function(value) {
      return _this.track.material.color.setHex(value.replace('#', '0x'));
    });
    this.trackFolder.add(this.track, 'forceWireframe');
    this.trackFolder.add(this.edit, 'debugNormals').onChange(function() {
      return _this.edit.renderCurve();
    });
    this.trackFolder.add(this.track, 'renderRails').onChange(function() {
      return _this.track.renderTrack();
    });
    this.trackFolder.add(this.spline, 'isConnected').onChange(function(value) {
      if (value) {
        _this.spline.connect();
      } else {
        _this.spline.disconnect();
      }
      return _this.edit.changed(true);
    });
    this.trackFolder.add({
      addPoint: function() {
        _this.spline.addControlPoint(_this.spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)));
        _this.edit.renderTrack();
        _this.track.renderTrack();
        return _this.edit.selectNode();
      }
    }, 'addPoint');
    this.onRideCamera = false;
    this.trainFolder = this.gui.addFolder('Train');
    this.trainFolder.open();
    this.trainFolder.addColor({
      color: '#ffffff'
    }, 'color').onChange(function(value) {
      return _this.train.carMaterial.color.setHex(value.replace('#', '0x'));
    });
    this.trainFolder.add(this.train, 'movementSpeed', 0.01, 0.1);
    this.trainFolder.add(this.train, 'numberOfCars', 0, 8).step(1).onChange(function(value) {
      return _this.train.rebuild();
    });
    this.trainFolder.add(this, 'onRideCamera').onChange(function(value) {
      if (value) {
        _this.oldCamPos = _this.renderer.camera.position.clone();
        _this.oldCamRot = _this.renderer.camera.rotation.clone();
        return LW.renderer.scene.remove(_this.edit);
      } else {
        _this.renderer.camera.position.copy(_this.oldCamPos);
        _this.renderer.camera.rotation.copy(_this.oldCamRot);
        return LW.renderer.scene.add(_this.edit);
      }
    });
    this.selected = {
      x: 0,
      y: 0,
      z: 0,
      bank: 0
    };
    updateVector = function(index, value) {
      if (!_this.selected.node) {
        return;
      }
      _this.selected.node.position[index] = value;
      _this.selected.node.splineVector[index] = value;
      return _this.edit.changed(true);
    };
    this.pointFolder = this.gui.addFolder('Point');
    this.pointFolder.add(this.selected, 'x').onChange(function(value) {
      return updateVector('x', value);
    });
    this.pointFolder.add(this.selected, 'y').onChange(function(value) {
      return updateVector('y', value);
    });
    this.pointFolder.add(this.selected, 'z').onChange(function(value) {
      return updateVector('z', value);
    });
    return this.pointFolder.add(this.selected, 'bank').onChange(function(value) {
      return updateVector('bank', value);
    });
  },
  selectionChanged: function(selected) {
    var controller, _i, _len, _ref;
    if (selected) {
      this.selected.x = selected.splineVector.x;
      this.selected.y = selected.splineVector.y;
      this.selected.z = selected.splineVector.z;
      this.selected.bank = selected.splineVector.bank || 0;
      this.selected.node = selected;
      _ref = this.pointFolder.__controllers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        controller = _ref[_i];
        controller.updateDisplay();
      }
      return this.pointFolder.open();
    } else {
      return this.pointFolder.close();
    }
  }
};

window.onload = function() {
  return LW.init();
};
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.BezierPath = (function(_super) {
  __extends(BezierPath, _super);

  BezierPath.fromJSON = function(vectorJSON) {
    var v, vec, vectors;
    vectors = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = vectorJSON.length; _i < _len; _i++) {
        v = vectorJSON[_i];
        vec = new THREE.Vector3(v.x, v.y, v.z);
        if (v.bank) {
          vec.setBank(v.bank);
        }
        _results.push(vec);
      }
      return _results;
    })();
    return new LW.BezierPath(vectors);
  };

  BezierPath.prototype.toJSON = function() {
    var vector, _i, _len, _ref, _results;
    _ref = this.vectors;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vector = _ref[_i];
      _results.push(vector.toJSON());
    }
    return _results;
  };

  function BezierPath(vectors) {
    this.vectors = vectors;
    if (vectors.length % 3 !== 0) {
      throw "wrong number of vectors";
    }
    BezierPath.__super__.constructor.call(this);
    this.rebuild();
  }

  BezierPath.prototype.rebuild = function() {
    var i, index, leftCP, leftHandle, rightCP, rightHandle, _i, _ref;
    while (this.curves.length) {
      this.curves.pop();
    }
    this.cacheLengths = [];
    for (i = _i = 0, _ref = this.vectors.length / 3 - 2; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      index = i * 3;
      leftCP = this.vectors[index + 1];
      rightCP = this.vectors[index + 4];
      leftHandle = this.vectors[index + 2].clone().add(leftCP);
      rightHandle = this.vectors[index + 3].clone().add(rightCP);
      this.add(new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP));
    }
    if (this.isConnected) {
      this.connect();
    }
  };

  BezierPath.prototype.isConnected = false;

  BezierPath.prototype.connect = function() {
    var leftCP, leftHandle, rightCP, rightHandle;
    this.isConnected = true;
    leftCP = this.vectors[this.vectors.length - 2];
    rightCP = this.vectors[1];
    leftHandle = this.vectors[this.vectors.length - 1].clone().add(leftCP);
    rightHandle = this.vectors[0].clone().add(rightCP);
    return this.curves.push(new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP));
  };

  BezierPath.prototype.disconnect = function() {
    this.isConnected = false;
    return this.curves.pop();
  };

  BezierPath.prototype.getBankAt = function(t) {
    var curve, curveLengths, d, diff, i, leftBank, rightBank, u, _ref, _ref1;
    d = t * this.getLength();
    curveLengths = this.getCurveLengths();
    i = 0;
    while (i < curveLengths.length) {
      if (curveLengths[i] >= d) {
        diff = curveLengths[i] - d;
        curve = this.curves[i];
        u = 1 - diff / curve.getLength();
        leftBank = ((_ref = curve.v0) != null ? _ref.bank : void 0) || 0;
        rightBank = ((_ref1 = curve.v3) != null ? _ref1.bank : void 0) || 0;
        return THREE.Curve.Utils.interpolate(leftBank, leftBank, rightBank, rightBank, u);
      }
      i++;
    }
    return 0;
  };

  BezierPath.prototype.addControlPoint = function(pos) {
    var last;
    last = this.vectors[this.vectors.length - 2];
    this.vectors.push(new THREE.Vector3(-10, 0, 0));
    this.vectors.push(pos.clone());
    this.vectors.push(new THREE.Vector3(10, 0, 0));
    return this._buildCurves();
  };

  return BezierPath;

})(THREE.CurvePath);

THREE.Vector3.prototype.toJSON = function() {
  var obj;
  obj = {
    x: this.x,
    y: this.y,
    z: this.z
  };
  if (this.bank) {
    obj.bank = this.bank;
  }
  return obj;
};

THREE.Vector3.prototype.setBank = function(amount) {
  this.bank = amount;
  return this;
};
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.Extruder = (function(_super) {
  __extends(Extruder, _super);

  function Extruder(spline, options) {
    this.spline = spline;
    this.drawTie = __bind(this.drawTie, this);
    Extruder.__super__.constructor.call(this);
    this.railRadius = options.railRadius, this.railDistance = options.railDistance, this.numberOfRails = options.numberOfRails, this.spineShape = options.spineShape, this.spineSteps = options.spineSteps, this.tieShape = options.tieShape, this.tieDistance = options.tieDistance, this.tieDepth = options.tieDepth;
    this.drawRail(this.railDistance, 0);
    this.drawRail(-this.railDistance, 0);
    this.computeCentroids();
    this.computeFaceNormals();
    this.computeVertexNormals();
    this.drawSpine(this.drawTie);
    this.computeCentroids();
    this.computeFaceNormals();
  }

  Extruder.prototype.drawSpine = function(stepCallback) {
    var a, b, binormal, binormals, c, d, face, faces, i, j, k, normal, normals, pos2, reverse, s, shapePoints, slen1, slen2, splinePoints, tangents, uvgen, uvs, vertex, vertexOffset, vertices, _i, _j, _k, _l, _len, _len1, _m, _ref, _ref1, _ref2, _ref3;
    if (!this.spineShape) {
      return;
    }
    splinePoints = this.spline.getSpacedPoints(this.spineSteps);
    uvgen = THREE.ExtrudeGeometry.WorldUVGenerator;
    _ref = LW.FrenetFrames(this.spline, this.spineSteps, false), tangents = _ref.tangents, normals = _ref.normals, binormals = _ref.binormals;
    binormal = new THREE.Vector3;
    normal = new THREE.Vector3;
    pos2 = new THREE.Vector3;
    shapePoints = this.spineShape.extractPoints(1);
    vertices = shapePoints.shape;
    reverse = !THREE.Shape.Utils.isClockWise(vertices);
    if (reverse) {
      vertices = vertices.reverse();
    }
    vertexOffset = this.vertices.length;
    faces = THREE.Shape.Utils.triangulateShape(vertices, []);
    for (s = _i = 0, _ref1 = this.spineSteps; 0 <= _ref1 ? _i <= _ref1 : _i >= _ref1; s = 0 <= _ref1 ? ++_i : --_i) {
      for (_j = 0, _len = vertices.length; _j < _len; _j++) {
        vertex = vertices[_j];
        normal.copy(normals[s]).multiplyScalar(vertex.x);
        binormal.copy(binormals[s]).multiplyScalar(vertex.y);
        pos2.copy(splinePoints[s]).add(normal).add(binormal);
        this.vertices.push(pos2.clone());
      }
    }
    for (_k = 0, _len1 = faces.length; _k < _len1; _k++) {
      face = faces[_k];
      this.faces.push(new THREE.Face3(face[0] + vertexOffset, face[1] + vertexOffset, face[2] + vertexOffset, null, null, null));
      uvs = uvgen.generateBottomUV(this, this.spineShape, null, face[2], face[1], face[0]);
      this.faceVertexUvs[0].push(uvs);
      a = face[0] + vertexOffset + vertices.length * this.spineSteps;
      b = face[1] + vertexOffset + vertices.length * this.spineSteps;
      c = face[2] + vertexOffset + vertices.length * this.spineSteps;
      this.faces.push(new THREE.Face3(c, b, a, null, null, null));
      uvs = uvgen.generateTopUV(this, this.spineShape, null, a, b, c);
      this.faceVertexUvs[0].push(uvs);
    }
    i = vertices.length;
    while (--i >= 0) {
      j = i;
      k = i - 1;
      if (k < 0) {
        k = vertices.length - 1;
      }
      for (s = _l = 0, _ref2 = this.spineSteps - 1; 0 <= _ref2 ? _l <= _ref2 : _l >= _ref2; s = 0 <= _ref2 ? ++_l : --_l) {
        slen1 = vertices.length * s;
        slen2 = vertices.length * (s + 1);
        a = j + slen1 + vertexOffset;
        b = k + slen1 + vertexOffset;
        c = k + slen2 + vertexOffset;
        d = j + slen2 + vertexOffset;
        this.faces.push(new THREE.Face3(d, b, a, null, null, null));
        this.faces.push(new THREE.Face3(d, c, b, null, null, null));
        uvs = uvgen.generateSideWallUV(this, this.spineShape, vertices, null, a, b, c, d, s, this.spineSteps, j, k);
        this.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]]);
        this.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]]);
      }
    }
    for (s = _m = 1, _ref3 = this.spineSteps; 1 <= _ref3 ? _m <= _ref3 : _m >= _ref3; s = 1 <= _ref3 ? ++_m : --_m) {
      if (typeof stepCallback === "function") {
        stepCallback(s, tangents, normals, binormals, splinePoints);
      }
    }
  };

  Extruder.prototype.drawTie = function(s, tangents, normals, binormals, splinePoints) {
    var a, b, binormal, bn, c, cross, d, face, i, j, k, n, normal, pos2, slen1, slen2, vertex, vertexOffset, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    if (!this.tieShape) {
      return;
    }
    pos2 = new THREE.Vector3;
    normal = new THREE.Vector3;
    binormal = new THREE.Vector3;
    cross = new THREE.Vector3;
    vertexOffset = this.vertices.length;
    this.tieVertices || (this.tieVertices = this.tieShape.extractPoints(1).shape);
    this.tieFaces || (this.tieFaces = THREE.Shape.Utils.triangulateShape(this.tieVertices, []));
    n = normals[s];
    bn = binormals[s];
    cross.copy(n).cross(bn).normalize().setLength(this.tieDepth / 2).negate();
    _ref = this.tieVertices;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      normal.copy(n).multiplyScalar(vertex.x);
      binormal.copy(bn).multiplyScalar(vertex.y);
      pos2.copy(splinePoints[s]).add(normal).add(binormal).add(cross);
      this.vertices.push(pos2.clone());
    }
    cross.negate();
    _ref1 = this.tieVertices;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      vertex = _ref1[_j];
      normal.copy(n).multiplyScalar(vertex.x);
      binormal.copy(bn).multiplyScalar(vertex.y);
      pos2.copy(splinePoints[s]).add(normal).add(binormal).add(cross);
      this.vertices.push(pos2.clone());
    }
    _ref2 = this.tieFaces;
    for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
      face = _ref2[_k];
      this.faces.push(new THREE.Face3(face[2] + vertexOffset, face[1] + vertexOffset, face[0] + vertexOffset, null, null, null));
      a = face[0] + vertexOffset + this.tieVertices.length;
      b = face[1] + vertexOffset + this.tieVertices.length;
      c = face[2] + vertexOffset + this.tieVertices.length;
      this.faces.push(new THREE.Face3(a, b, c, null, null, null));
    }
    i = this.tieVertices.length;
    while (--i >= 0) {
      j = i;
      k = i - 1;
      if (k < 0) {
        k = this.tieVertices.length - 1;
      }
      slen1 = this.tieVertices.length;
      slen2 = 0;
      a = j + slen1 + vertexOffset;
      b = k + slen1 + vertexOffset;
      c = k + slen2 + vertexOffset;
      d = j + slen2 + vertexOffset;
      this.faces.push(new THREE.Face3(a, b, d, null, null, null));
      this.faces.push(new THREE.Face3(b, c, d, null, null, null));
    }
  };

  Extruder.prototype.drawRail = function(xDistance, yDistance) {
    var a, b, binormal, binormals, c, cx, cy, d, grid, i, ip, j, jp, normal, normals, pos, pos2, segments, tangent, tangents, u, uva, uvb, uvc, uvd, v, _i, _j, _k, _l, _ref, _ref1, _ref2, _ref3;
    if (!this.numberOfRails) {
      return;
    }
    segments = Math.floor(this.spline.getLength());
    _ref = LW.FrenetFrames(this.spline, segments), tangents = _ref.tangents, normals = _ref.normals, binormals = _ref.binormals;
    pos = pos2 = new THREE.Vector3;
    this.radialSegments = 8;
    grid = [];
    for (i = _i = 0; 0 <= segments ? _i <= segments : _i >= segments; i = 0 <= segments ? ++_i : --_i) {
      grid[i] = [];
      u = i / segments;
      pos = this.spline.getPointAt(u);
      tangent = tangents[i];
      normal = normals[i];
      binormal = binormals[i];
      for (j = _j = 0, _ref1 = this.radialSegments; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
        v = j / this.radialSegments * 2 * Math.PI;
        cx = -this.railRadius * Math.cos(v) + xDistance;
        cy = this.railRadius * Math.sin(v) + yDistance;
        pos2.copy(pos);
        pos2.x += cx * normal.x + cy * binormal.x;
        pos2.y += cx * normal.y + cy * binormal.y;
        pos2.z += cx * normal.z + cy * binormal.z;
        grid[i][j] = this.vertices.push(pos2.clone()) - 1;
      }
    }
    for (i = _k = 0, _ref2 = segments - 1; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; i = 0 <= _ref2 ? ++_k : --_k) {
      for (j = _l = 0, _ref3 = this.radialSegments; 0 <= _ref3 ? _l <= _ref3 : _l >= _ref3; j = 0 <= _ref3 ? ++_l : --_l) {
        ip = i + 1;
        jp = (j + 1) % this.radialSegments;
        a = grid[i][j];
        b = grid[ip][j];
        c = grid[ip][jp];
        d = grid[i][jp];
        uva = new THREE.Vector2(i / segments, j / this.radialSegments);
        uvb = new THREE.Vector2((i + 1) / segments, j / this.radialSegments);
        uvc = new THREE.Vector2((i + 1) / segments, (j + 1) / this.radialSegments);
        uvd = new THREE.Vector2(i / segments, (j + 1) / this.radialSegments);
        this.faces.push(new THREE.Face3(d, b, a));
        this.faceVertexUvs[0].push([uva, uvb, uvd]);
        this.faces.push(new THREE.Face3(d, c, b));
        this.faceVertexUvs[0].push([uvb.clone(), uvc, uvd.clone()]);
      }
    }
  };

  return Extruder;

})(THREE.Geometry);
LW.FrenetFrames = function(path, segments) {
  var bank, binormals, i, normals, tangents, u, up, _i;
  tangents = [];
  normals = [];
  binormals = [];
  up = new THREE.Vector3(0, 1, 0);
  for (i = _i = 0; 0 <= segments ? _i <= segments : _i >= segments; i = 0 <= segments ? ++_i : --_i) {
    u = i / segments;
    tangents[i] = path.getTangentAt(u).normalize();
    bank = THREE.Math.degToRad(path.getBankAt(u));
    binormals[i] = up.clone().applyAxisAngle(tangents[i], bank);
    normals[i] = tangents[i].clone().cross(binormals[i]).normalize();
    binormals[i] = normals[i].clone().cross(tangents[i]).normalize();
  }
  return {
    tangents: tangents,
    normals: normals,
    binormals: binormals
  };
};
LW.Spline = (function() {
  function Spline() {}

  return Spline;

})();
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

LW.Renderer = (function() {
  function Renderer() {
    this.render = __bind(this.render, this);
    var x, y, zoom;
    this.renderer = new THREE.WebGLRenderer({
      antialias: true
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setClearColor(0xf0f0f0);
    this.renderer.autoClear = false;
    this.domElement = this.renderer.domElement;
    this.scene = new THREE.Scene;
    this.clock = new THREE.Clock();
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000);
    this.camera.shouldRotate = true;
    this.camera.position.z += 60;
    zoom = 16;
    x = window.innerWidth / zoom;
    y = window.innerHeight / zoom;
    this.topCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000);
    this.topCamera.zoom = zoom;
    this.topCamera.up = new THREE.Vector3(0, 0, -1);
    this.topCamera.lookAt(new THREE.Vector3(0, -1, 0));
    this.scene.add(this.topCamera);
    this.frontCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000);
    this.frontCamera.zoom = zoom;
    this.frontCamera.lookAt(new THREE.Vector3(0, 0, -1));
    this.scene.add(this.frontCamera);
    this.sideCamera = new THREE.OrthographicCamera(-x, x, y, -y, -5000, 10000);
    this.sideCamera.zoom = zoom;
    this.sideCamera.lookAt(new THREE.Vector3(1, 0, 0));
    this.scene.add(this.sideCamera);
    this.light = new THREE.PointLight(0xffffff);
    this.light.position.set(20, 40, 0);
    this.scene.add(this.light);
  }

  Renderer.prototype.render = function() {
    var SCREEN_HEIGHT, SCREEN_WIDTH, _ref;
    if ((_ref = LW.train) != null) {
      _ref.simulate(this.clock.getDelta());
    }
    SCREEN_WIDTH = window.innerWidth * this.renderer.devicePixelRatio;
    SCREEN_HEIGHT = window.innerHeight * this.renderer.devicePixelRatio;
    this.renderer.clear();
    LW.track.material.wireframe = true;
    this.renderer.setViewport(1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
    this.renderer.render(this.scene, this.topCamera);
    this.renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
    this.renderer.render(this.scene, this.sideCamera);
    this.renderer.setViewport(1, 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
    this.renderer.render(this.scene, this.frontCamera);
    LW.track.material.wireframe = LW.track.forceWireframe || false;
    this.renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
    this.renderer.render(this.scene, this.camera);
    return requestAnimationFrame(this.render);
  };

  return Renderer;

})();
LW.Terrain = (function() {
  function Terrain(renderer) {
    var format, geo, groundMaterial, groundTexture, material, mesh, path, shader, textureCube, urls;
    geo = new THREE.PlaneGeometry(1000, 1000, 125, 125);
    groundMaterial = new THREE.MeshPhongMaterial({
      color: 0xffffff,
      specular: 0x111111
    });
    groundTexture = THREE.ImageUtils.loadTexture("resources/textures/grass.jpg", void 0, function() {
      groundMaterial.map = groundTexture;
      groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping;
      groundTexture.repeat.set(25, 25);
      groundTexture.anisotropy = 16;
      this.ground = new THREE.Mesh(geo, groundMaterial);
      this.ground.position.y -= 5;
      this.ground.rotation.x = -Math.PI / 2;
      return renderer.scene.add(this.ground);
    });
    path = "resources/textures/skybox/";
    format = '.jpg';
    urls = [path + 'px' + format, path + 'nx' + format, path + 'py' + format, path + 'ny' + format, path + 'pz' + format, path + 'nz' + format];
    textureCube = THREE.ImageUtils.loadTextureCube(urls, new THREE.CubeRefractionMapping());
    material = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      envMap: textureCube,
      refractionRatio: 0.95
    });
    shader = THREE.ShaderLib["cube"];
    shader.uniforms["tCube"].value = textureCube;
    material = new THREE.ShaderMaterial({
      fragmentShader: shader.fragmentShader,
      vertexShader: shader.vertexShader,
      uniforms: shader.uniforms,
      side: THREE.BackSide
    });
    mesh = new THREE.Mesh(new THREE.CubeGeometry(10000, 10000, 10000), material);
    renderer.scene.add(mesh);
  }

  Terrain.prototype.render = function() {};

  return Terrain;

})();
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.Train = (function(_super) {
  var up;

  __extends(Train, _super);

  function Train(options) {
    Train.__super__.constructor.call(this);
    this.numberOfCars = options.numberOfCars, this.carGeometry = options.carGeometry, this.carMaterial = options.carMaterial, this.carSpacing = options.carSpacing, this.carLength = options.carLength, this.movementSpeed = options.movementSpeed;
    this.cars = [];
    this.rebuild();
    this.movementSpeed || (this.movementSpeed = 0.08);
  }

  Train.prototype.rebuild = function() {
    var car, i, _i, _ref;
    this.carGeometry || (this.carGeometry = new THREE.CubeGeometry(8, 8, 16));
    this.carMaterial || (this.carMaterial = new THREE.MeshLambertMaterial({
      color: 0xeeeeee
    }));
    this.carSpacing || (this.carSpacing = 2);
    this.carLength || (this.carLength = 16);
    while (this.cars.length) {
      this.remove(this.cars.pop());
    }
    if (this.numberOfCars) {
      for (i = _i = 0, _ref = this.numberOfCars - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        car = new THREE.Mesh(this.carGeometry, this.carMaterial);
        this.cars.push(car);
        this.add(car);
      }
    }
    return this.currentTime = 0.0;
  };

  Train.prototype.attachToTrack = function(track) {
    this.track = track;
    return this.spline = this.track.spline;
  };

  up = new THREE.Vector3(0, 1, 0);

  Train.prototype.simulate = function(delta) {
    var bank, binormal, car, deltaPoint, desiredDistance, i, lastPos, mat, normal, pos, tangent, _i, _len, _ref;
    if (!this.numberOfCars) {
      return;
    }
    this.currentTime += this.movementSpeed * delta;
    if (this.currentTime > 1) {
      this.currentTime = 0;
    }
    lastPos = this.spline.getPointAt(this.currentTime);
    _ref = this.cars;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      car = _ref[i];
      pos = null;
      desiredDistance = i * 18;
      deltaPoint = this.currentTime;
      if (desiredDistance > 0) {
        while (deltaPoint > 0) {
          pos = this.spline.getPointAt(deltaPoint);
          if (pos.distanceTo(lastPos) >= desiredDistance) {
            break;
          }
          deltaPoint += 0.01;
          if (deltaPoint > 1) {
            deltaPoint = 0;
          }
        }
      } else {
        pos = lastPos;
      }
      if (pos) {
        tangent = this.spline.getTangentAt(deltaPoint).normalize();
        bank = THREE.Math.degToRad(this.spline.getBankAt(deltaPoint));
        binormal = up.clone().applyAxisAngle(tangent, bank);
        normal = tangent.clone().cross(binormal).normalize();
        binormal = normal.clone().cross(tangent).normalize();
        mat = new THREE.Matrix4(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1);
        car.position.copy(pos).add(new THREE.Vector3(0, 5, 0).applyMatrix4(mat));
        car.rotation.setFromRotationMatrix(mat);
        if (LW.onRideCamera) {
          LW.renderer.camera.position.copy(pos).add(new THREE.Vector3(0, 3, 0).applyMatrix4(mat));
          LW.renderer.camera.rotation.setFromRotationMatrix(mat);
        }
      }
    }
  };

  return Train;

})(THREE.Object3D);
var CONTROL_COLOR, POINT_COLOR, SELECTED_COLOR,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CONTROL_COLOR = 0x0000ee;

POINT_COLOR = 0xdddddd;

SELECTED_COLOR = 0xffffff;

LW.EditTrack = (function(_super) {
  __extends(EditTrack, _super);

  EditTrack.prototype.debugNormals = false;

  function EditTrack(spline) {
    var _this = this;
    this.spline = spline;
    this.onMouseUp = __bind(this.onMouseUp, this);
    this.onMouseDown = __bind(this.onMouseDown, this);
    EditTrack.__super__.constructor.call(this);
    this.arrows = [];
    this.mouseDown = new THREE.Vector2;
    this.mouseUp = new THREE.Vector2;
    this.projector = new THREE.Projector;
    this.raycaster = new THREE.Raycaster;
    this.transformControl = new THREE.TransformControls(LW.renderer.camera, LW.renderer.domElement);
    LW.renderer.scene.add(this.transformControl);
    this.transformControl.addEventListener('change', function() {
      var _ref;
      if ((_ref = LW.controls) != null) {
        _ref.enabled = _this.transformControl.axis === void 0;
      }
      return _this.changed();
    });
    LW.renderer.domElement.addEventListener('mousedown', this.onMouseDown, false);
    LW.renderer.domElement.addEventListener('mouseup', this.onMouseUp, false);
  }

  EditTrack.prototype.changed = function(force) {
    var oppositeHandle,
      _this = this;
    if (this.selected && this.transformControl.axis !== void 0) {
      if (this.selectedHandle) {
        this.selected.pointLine.geometry.verticesNeedUpdate = true;
        oppositeHandle = this.selectedHandle === this.selected.left ? this.selected.right : this.selected.left;
        oppositeHandle.position.copy(this.selectedHandle.position).negate();
      }
      this.selected.splineVector.copy(this.selected.position);
      this.selected.left.splineVector.copy(this.selected.left.position);
      this.selected.right.splineVector.copy(this.selected.right.position);
    }
    if (this.selected || force) {
      this.spline.rebuild();
      if (!this.rerenderTimeout) {
        this.rerenderTimeout = setTimeout(function() {
          localStorage.setItem('track', JSON.stringify(_this.spline));
          _this.rerenderTimeout = null;
          _this.renderCurve();
          return LW.track.renderTrack();
        }, 10);
      }
    }
  };

  EditTrack.prototype.pick = function(pos, objects) {
    var camera, ray, vector, x, y;
    camera = LW.controls.camera;
    x = pos.x, y = pos.y;
    if (x > 0.5) {
      x -= 0.5;
    }
    if (y > 0.5) {
      y -= 0.5;
    }
    vector = new THREE.Vector3(x * 4 - 1, -y * 4 + 1, 0.5);
    if (camera instanceof THREE.PerspectiveCamera) {
      this.projector.unprojectVector(vector, camera);
      this.raycaster.set(camera.position, vector.sub(camera.position).normalize());
      return this.raycaster.intersectObjects(objects);
    } else {
      ray = this.projector.pickingRay(vector, camera);
      return ray.intersectObjects(objects);
    }
  };

  EditTrack.prototype.onMouseDown = function(event) {
    this.mouseDown.x = event.clientX / window.innerWidth;
    this.mouseDown.y = event.clientY / window.innerHeight;
    return this.isMouseDown = true;
  };

  EditTrack.prototype.onMouseUp = function(event) {
    var intersects, nodes, object;
    if (!this.isMouseDown) {
      return;
    }
    this.mouseUp.x = event.clientX / window.innerWidth;
    this.mouseUp.y = event.clientY / window.innerHeight;
    if (this.mouseDown.distanceTo(this.mouseUp) === 0) {
      nodes = this.selected ? this.controlPoints.concat([this.selected.left, this.selected.right]) : this.controlPoints;
      intersects = this.pick(this.mouseUp, nodes);
      this.transformControl.detach();
      if (intersects.length > 0) {
        object = intersects[0].object;
        if (object.isControl) {
          this.selectedHandle = null;
          this.selectNode(object);
        } else {
          this.selectedHandle = object;
          this.transformControl.attach(object);
        }
      } else {
        this.selectedHandle = null;
        this.selectNode(null);
      }
    }
    return this.isMouseDown = false;
  };

  EditTrack.prototype.selectNode = function(node) {
    var _ref;
    if (node === void 0) {
      node = this.controlPoints[this.controlPoints.length - 1];
    }
    if ((_ref = this.selected) != null) {
      _ref.select(false);
    }
    this.selected = node;
    if (node) {
      node.select(true);
      this.transformControl.attach(node);
    }
    return LW.selectionChanged(node);
  };

  EditTrack.prototype.renderTrack = function() {
    var i, isControl, lastNode, node, vector, _i, _len, _ref;
    this.clear();
    this.controlPoints = [];
    lastNode = null;
    if (LW.onRideCamera) {
      return;
    }
    _ref = this.spline.vectors;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      vector = _ref[i];
      isControl = (i - 1) % 3 === 0;
      node = new LW.EditNode(isControl);
      node.position.copy(vector);
      node.splineVector = vector;
      if (isControl) {
        this.add(node);
        node.left = lastNode;
        node.add(lastNode);
        this.controlPoints.push(node);
      } else if (lastNode != null ? lastNode.isControl : void 0) {
        lastNode.add(node);
        lastNode.right = node;
        lastNode.addLine();
      }
      lastNode = node;
    }
    return this.renderCurve();
  };

  EditTrack.prototype.renderCurve = function() {
    var arrow, ba, binormals, geo, i, mat, na, normal, normals, pos, steps, _i, _j, _len, _len1, _ref, _ref1;
    if (this.line) {
      this.remove(this.line);
    }
    _ref = this.arrows;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      arrow = _ref[_i];
      this.remove(arrow);
    }
    if (LW.onRideCamera) {
      return;
    }
    geo = this.spline.createPointsGeometry(this.spline.getLength());
    mat = new THREE.LineBasicMaterial({
      color: 0xff0000,
      linewidth: 2
    });
    this.line = new THREE.Line(geo, mat);
    this.add(this.line);
    if (this.debugNormals) {
      steps = this.spline.getLength() / 2;
      _ref1 = LW.FrenetFrames(this.spline, steps), normals = _ref1.normals, binormals = _ref1.binormals;
      for (i = _j = 0, _len1 = normals.length; _j < _len1; i = ++_j) {
        normal = normals[i];
        pos = this.spline.getPointAt(i / steps);
        na = new THREE.ArrowHelper(normal, pos, 5, 0x00ff00);
        ba = new THREE.ArrowHelper(binormals[i], pos, 5, 0x0000ff);
        this.add(na);
        this.add(ba);
        this.arrows.push(na, ba);
      }
    }
  };

  return EditTrack;

})(THREE.Object3D);

LW.EditNode = (function(_super) {
  __extends(EditNode, _super);

  function EditNode(isControl) {
    var geo, mat;
    this.isControl = isControl;
    geo = new THREE.SphereGeometry(1);
    mat = new THREE.MeshLambertMaterial({
      color: isControl ? CONTROL_COLOR : POINT_COLOR
    });
    EditNode.__super__.constructor.call(this, geo, mat);
    this.visible = isControl;
  }

  EditNode.prototype.addLine = function() {
    var geo, mat;
    geo = new THREE.Geometry;
    geo.vertices.push(this.left.position);
    geo.vertices.push(new THREE.Vector3);
    geo.vertices.push(this.right.position);
    mat = new THREE.LineBasicMaterial({
      color: POINT_COLOR,
      linewidth: 4
    });
    this.pointLine = new THREE.Line(geo, mat);
    this.pointLine.visible = false;
    return this.add(this.pointLine);
  };

  EditNode.prototype.select = function(selected) {
    var _ref, _ref1, _ref2;
    this.material.color.setHex(selected ? SELECTED_COLOR : CONTROL_COLOR);
    if ((_ref = this.left) != null) {
      _ref.visible = selected;
    }
    if ((_ref1 = this.right) != null) {
      _ref1.visible = selected;
    }
    return (_ref2 = this.pointLine) != null ? _ref2.visible = selected : void 0;
  };

  return EditNode;

})(THREE.Mesh);
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.BMTrack = (function(_super) {
  __extends(BMTrack, _super);

  function BMTrack(spline) {
    this.spline = spline;
    BMTrack.__super__.constructor.call(this);
    this.material = new THREE.MeshLambertMaterial({
      color: 0xff0000,
      wireframe: true
    });
  }

  BMTrack.prototype.renderTrack = function() {
    var boxGeo, boxMesh, boxShape, boxSize, numberOfRails, offsetX, offsetY, radius, steps, tieShape;
    this.clear();
    boxSize = 2;
    offsetY = -3.5;
    boxShape = new THREE.Shape;
    boxShape.moveTo(-boxSize, -boxSize + offsetY);
    boxShape.lineTo(-boxSize, boxSize + offsetY);
    boxShape.lineTo(boxSize, boxSize + offsetY);
    boxShape.lineTo(boxSize, -boxSize + offsetY);
    boxShape.lineTo(-boxSize, -boxSize + offsetY);
    radius = 0.5;
    offsetX = boxSize + 1.5;
    offsetY = 0;
    tieShape = new THREE.Shape;
    tieShape.moveTo(boxSize, boxSize - 3.5 - boxSize / 4);
    tieShape.lineTo(offsetX, offsetY);
    tieShape.lineTo(offsetX - radius, offsetY);
    tieShape.lineTo(boxSize / 2, boxSize - 3);
    tieShape.lineTo(-boxSize / 2, boxSize - 3);
    tieShape.lineTo(-offsetX + radius, offsetY);
    tieShape.lineTo(-offsetX, offsetY);
    tieShape.lineTo(-boxSize, boxSize - 3.5 - boxSize / 4);
    steps = this.spline.getLength();
    numberOfRails = this.renderRails ? 2 : 0;
    boxGeo = new LW.Extruder(this.spline, {
      spineShape: boxShape,
      spineSteps: Math.ceil(steps / 8),
      tieShape: tieShape,
      tieDepth: 0.65,
      numberOfRails: numberOfRails,
      railRadius: radius,
      railDistance: offsetX - radius
    });
    boxMesh = new THREE.Mesh(boxGeo, this.material);
    return this.add(boxMesh);
  };

  return BMTrack;

})(THREE.Object3D);
