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
      this.spline = new LW.BezierPath([new LW.Point(-40, 0, 0, -10, 0, 0, 10, 0, 0), new LW.Point(0, 18, 0, -10, -20, 0, 10, 20, 0).setSegmentType(1), new LW.Point(47, 20, 40, -14, -10, -40, 14, 10, 40).setBank(60), new LW.Point(0, 0, 80, 30, 0, 0, -30, 0, 0).setBank(20), new LW.Point(-80, 0, 80, 18, 0, 0, -18, 0, 0).setBank(-359), new LW.Point(-120, 0, 40, 2.5, 0, 23, -2.5, 0, -23).setBank(-359), new LW.Point(-80, 0, 0, -33, 0, 0, 33, 0, 0).setBank(-359)]);
    }
    this.edit = new LW.EditTrack(this.spline);
    this.edit.renderTrack();
    renderer.scene.add(this.edit);
    this.track = new LW.BMTrack(this.spline);
    this.track.forceWireframe = false;
    this.track.rebuild();
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
    this.gui.add(this.renderer, 'useQuadView');
    this.trackFolder = this.gui.addFolder('Track');
    this.trackFolder.open();
    this.trackFolder.addColor({
      spineColor: "#ff0000"
    }, 'spineColor').onChange(function(value) {
      return _this.track.spineMaterial.color.setHex(value.replace('#', '0x'));
    });
    this.trackFolder.addColor({
      tieColor: "#ff0000"
    }, 'tieColor').onChange(function(value) {
      return _this.track.tieMaterial.color.setHex(value.replace('#', '0x'));
    });
    this.trackFolder.addColor({
      railColor: "#ff0000"
    }, 'railColor').onChange(function(value) {
      return _this.track.railMaterial.color.setHex(value.replace('#', '0x'));
    });
    this.trackFolder.add(this.track, 'forceWireframe');
    this.trackFolder.add(this.track, 'debugNormals').onChange(function() {
      return _this.track.rebuild();
    });
    this.trackFolder.add(this.spline, 'isConnected').onChange(function(value) {
      _this.spline.isConnected = value;
      return _this.edit.changed(true);
    });
    this.trackFolder.add({
      addPoint: function() {
        _this.spline.addControlPoint(_this.spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)));
        _this.edit.renderTrack();
        _this.track.rebuild();
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
      if (index === 'x' || index === 'y' || index === 'z') {
        _this.selected.node.position[index] = value;
      } else {
        _this.selected.node.point[index] = value;
      }
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
      this.selected.x = selected.position.x;
      this.selected.y = selected.position.y;
      this.selected.z = selected.position.z;
      this.selected.bank = selected.point.bank || 0;
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

  BezierPath.fromJSON = function(json) {
    var p, points;
    points = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = json.length; _i < _len; _i++) {
        p = json[_i];
        _results.push(new LW.Point.fromJSON(p));
      }
      return _results;
    })();
    return new LW.BezierPath(points);
  };

  BezierPath.prototype.toJSON = function() {
    var p, _i, _len, _ref, _results;
    _ref = this.points;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      _results.push(p.toJSON());
    }
    return _results;
  };

  function BezierPath(points) {
    this.points = points;
    BezierPath.__super__.constructor.call(this);
    this.rebuild();
  }

  BezierPath.prototype.rebuild = function() {
    var curve, i, leftCP, leftHandle, p1, p2, rightCP, rightHandle, _i, _len, _ref;
    while (this.curves.length) {
      this.curves.pop();
    }
    this.cacheLengths = [];
    _ref = this.points;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      p1 = _ref[i];
      if (i === this.points.length - 1) {
        if (!this.isConnected) {
          return;
        }
        p2 = this.points[0];
      } else {
        p2 = this.points[i + 1];
      }
      leftCP = p1.position;
      rightCP = p2.position;
      leftHandle = p1.right.clone().add(leftCP);
      rightHandle = p2.left.clone().add(rightCP);
      curve = new THREE.CubicBezierCurve3(leftCP, leftHandle, rightHandle, rightCP);
      curve.p1 = p1;
      curve.p2 = p2;
      this.add(curve);
    }
  };

  BezierPath.prototype.isConnected = false;

  BezierPath.prototype.getCurveAt = function(t) {
    var curveLengths, d, i;
    d = t * this.getLength();
    curveLengths = this.getCurveLengths();
    i = 0;
    while (i < curveLengths.length) {
      if (curveLengths[i] >= d) {
        return this.curves[i];
      }
      i++;
    }
    return null;
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
        leftBank = ((_ref = curve.p1) != null ? _ref.bank : void 0) || 0;
        rightBank = ((_ref1 = curve.p2) != null ? _ref1.bank : void 0) || 0;
        return THREE.Curve.Utils.interpolate(leftBank, leftBank, rightBank, rightBank, u);
      }
      i++;
    }
    return 0;
  };

  BezierPath.prototype.addControlPoint = function(pos) {
    this.points.push(new LW.Point(pos.x, pos.y, pos.z, -10, 0, 0, 10, 0, 0));
    return this.rebuild();
  };

  return BezierPath;

})(THREE.CurvePath);

LW.Point = (function() {
  Point.prototype.position = null;

  Point.prototype.bank = 0;

  Point.prototype.segmentType = 0;

  function Point(x, y, z, lx, ly, lz, rx, ry, rz) {
    this.position = new THREE.Vector3(x, y, z);
    this.left = new THREE.Vector3(lx, ly, lz);
    this.right = new THREE.Vector3(rx, ry, rz);
  }

  Point.prototype.setBank = function(amount) {
    this.bank = amount;
    return this;
  };

  Point.prototype.setSegmentType = function(type) {
    this.segmentType = type;
    return this;
  };

  Point.prototype.toJSON = function() {
    var obj;
    obj = {
      position: this.position,
      left: this.left,
      right: this.right
    };
    if (this.bank) {
      obj.bank = this.bank;
    }
    if (this.segmentType) {
      obj.segmentType = this.segmentType;
    }
    return obj;
  };

  Point.fromJSON = function(json) {
    var p;
    p = new LW.Point;
    p.position.copy(json.position);
    p.left.copy(json.left);
    p.right.copy(json.right);
    if (json.bank) {
      p.bank = json.bank;
    }
    if (json.segmentType) {
      p.segmentType = json.segmentType;
    }
    return p;
  };

  return Point;

})();
LW.Spline = (function() {
  function Spline() {}

  return Spline;

})();
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

LW.Renderer = (function() {
  Renderer.prototype.useQuadView = false;

  function Renderer() {
    this.render = __bind(this.render, this);
    var sideLight, x, y, zoom;
    this.renderer = new THREE.WebGLRenderer({
      antialias: true
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setClearColor(0xf0f0f0);
    this.renderer.autoClear = false;
    this.renderer.gammaInput = true;
    this.renderer.gammaOutput = true;
    this.renderer.physicallyBasedShading = true;
    this.renderer.shadowMapEnabled = true;
    this.renderer.shadowMapType = THREE.PCFSoftShadowMap;
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
    this.light = new THREE.DirectionalLight(0xffffff, 0.8);
    this.light.position.set(0, 1000, 0);
    this.light.castShadow = true;
    this.light.shadowMapWidth = 4096;
    this.light.shadowMapHeight = 4096;
    this.scene.add(this.light);
    this.bottomLight = new THREE.DirectionalLight(0xffffff, 0.5);
    this.bottomLight.position.set(0, -1, 0);
    this.scene.add(this.bottomLight);
    sideLight = new THREE.DirectionalLight(0xffffff, 0.3);
    sideLight.position.set(0, 0, -1);
    this.scene.add(sideLight);
    sideLight = new THREE.DirectionalLight(0xffffff, 0.3);
    sideLight.position.set(0, 0, 1);
    this.scene.add(sideLight);
  }

  Renderer.prototype.render = function() {
    var SCREEN_HEIGHT, SCREEN_WIDTH, mat, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if ((_ref = LW.train) != null) {
      _ref.simulate(this.clock.getDelta());
    }
    SCREEN_WIDTH = window.innerWidth * this.renderer.devicePixelRatio;
    SCREEN_HEIGHT = window.innerHeight * this.renderer.devicePixelRatio;
    this.renderer.clear();
    if (this.useQuadView) {
      _ref1 = LW.track.materials;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        mat = _ref1[_i];
        mat.wireframe = true;
      }
      this.renderer.setViewport(1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
      this.renderer.render(this.scene, this.topCamera);
      this.renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 0.5 * SCREEN_HEIGHT + 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
      this.renderer.render(this.scene, this.sideCamera);
      this.renderer.setViewport(1, 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
      this.renderer.render(this.scene, this.frontCamera);
      this.renderer.setViewport(0.5 * SCREEN_WIDTH + 1, 1, 0.5 * SCREEN_WIDTH - 2, 0.5 * SCREEN_HEIGHT - 2);
    } else {
      this.renderer.setViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
    _ref2 = LW.track.materials;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      mat = _ref2[_j];
      mat.wireframe = LW.track.forceWireframe || false;
    }
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
      this.ground.position.y -= 10;
      this.ground.rotation.x = -Math.PI / 2;
      this.ground.receiveShadow = true;
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

LW.Track = (function(_super) {
  var UP, uvgen, _binormal, _cross, _normal, _pos;

  __extends(Track, _super);

  Track.prototype.railRadius = 1;

  Track.prototype.railDistance = 2;

  Track.prototype.railRadialSegments = 8;

  Track.prototype.numberOfRails = 2;

  Track.prototype.spineShape = null;

  Track.prototype.spineDivisionLength = 5;

  Track.prototype.spineShapeNeedsUpdate = true;

  Track.prototype.tieShape = null;

  Track.prototype.tieDepth = 1;

  Track.prototype.tieShapeNeedsUpdate = true;

  Track.prototype.debugNormals = false;

  function Track(spline, options) {
    var key, value;
    this.spline = spline;
    Track.__super__.constructor.call(this);
    for (key in options) {
      value = options[key];
      this[key] = value;
    }
  }

  UP = new THREE.Vector3(0, 1, 0);

  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator;

  Track.prototype.rebuild = function() {
    var bank, binormal, curve, i, lastSpineCurve, lastSpinePos, normal, pos, spineSteps, tangent, totalLength, u, _i;
    this.clear();
    this.prepareRails();
    this.prepareTies();
    this.prepareSpine();
    totalLength = Math.ceil(this.spline.getLength());
    spineSteps = 0;
    binormal = new THREE.Vector3;
    normal = new THREE.Vector3;
    for (i = _i = 0; 0 <= totalLength ? _i <= totalLength : _i >= totalLength; i = 0 <= totalLength ? ++_i : --_i) {
      u = i / totalLength;
      curve = this.spline.getCurveAt(u);
      pos = this.spline.getPointAt(u);
      tangent = this.spline.getTangentAt(u).normalize();
      bank = THREE.Math.degToRad(this.spline.getBankAt(u));
      binormal.copy(UP).applyAxisAngle(tangent, bank);
      normal.crossVectors(tangent, binormal).normalize();
      binormal.crossVectors(normal, tangent).normalize();
      if (!lastSpinePos || lastSpinePos.distanceTo(pos) >= this.spineDivisionLength) {
        this.tieStep(pos, normal, binormal, curve !== lastSpineCurve);
        this.spineStep(pos, normal, binormal);
        spineSteps++;
        lastSpinePos = pos;
        lastSpineCurve = curve;
      }
      this.railStep(pos, normal, binormal);
      if (this.debugNormals) {
        this.add(new THREE.ArrowHelper(normal, pos, 5, 0x00ff00));
        this.add(new THREE.ArrowHelper(binormal, pos, 5, 0x0000ff));
      }
    }
    this.spineStep(pos, normal, binormal);
    this.finalizeRails(totalLength);
    this.finalizeTies(spineSteps);
    return this.finalizeSpine(spineSteps);
  };

  /*
  # Rail Drawing
  */


  Track.prototype.prepareRails = function() {
    var i, _i, _ref, _results;
    this.railGeometry = new THREE.Geometry;
    this._railGrids = [];
    _results = [];
    for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      _results.push(this._railGrids.push([]));
    }
    return _results;
  };

  Track.prototype.railStep = function(pos, normal, binormal) {
    var cx, cy, grid, i, j, v, xDistance, yDistance, _i, _j, _ref, _ref1, _results;
    if (!this.numberOfRails) {
      return;
    }
    _results = [];
    for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      grid = [];
      xDistance = i % 2 === 0 ? this.railDistance : -this.railDistance;
      yDistance = i > 1 ? -this.railDistance : 0;
      for (j = _j = 0, _ref1 = this.railRadialSegments; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
        v = j / this.railRadialSegments * 2 * Math.PI;
        cx = -this.railRadius * Math.cos(v) + xDistance;
        cy = this.railRadius * Math.sin(v) + yDistance;
        _pos.copy(pos);
        _pos.x += cx * normal.x + cy * binormal.x;
        _pos.y += cx * normal.y + cy * binormal.y;
        _pos.z += cx * normal.z + cy * binormal.z;
        grid.push(this.railGeometry.vertices.push(_pos.clone()) - 1);
      }
      _results.push(this._railGrids[i].push(grid));
    }
    return _results;
  };

  Track.prototype.finalizeRails = function(steps) {
    var a, b, c, d, i, ip, j, jp, n, uva, uvb, uvc, uvd, _i, _j, _k, _ref, _ref1, _ref2;
    for (n = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; n = 0 <= _ref ? ++_i : --_i) {
      for (i = _j = 0, _ref1 = steps - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
        for (j = _k = 0, _ref2 = this.railRadialSegments; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; j = 0 <= _ref2 ? ++_k : --_k) {
          ip = i + 1;
          jp = (j + 1) % this.railRadialSegments;
          a = this._railGrids[n][i][j];
          b = this._railGrids[n][ip][j];
          c = this._railGrids[n][ip][jp];
          d = this._railGrids[n][i][jp];
          uva = new THREE.Vector2(i / steps, j / this.railRadialSegments);
          uvb = new THREE.Vector2((i + 1) / steps, j / this.railRadialSegments);
          uvc = new THREE.Vector2((i + 1) / steps, (j + 1) / this.railRadialSegments);
          uvd = new THREE.Vector2(i / steps, (j + 1) / this.railRadialSegments);
          this.railGeometry.faces.push(new THREE.Face3(d, b, a));
          this.railGeometry.faceVertexUvs[0].push([uva, uvb, uvd]);
          this.railGeometry.faces.push(new THREE.Face3(d, c, b));
          this.railGeometry.faceVertexUvs[0].push([uvb.clone(), uvc, uvd.clone()]);
        }
      }
    }
    this.railGeometry.computeCentroids();
    this.railGeometry.computeFaceNormals();
    this.railGeometry.computeVertexNormals();
    this.railMesh = new THREE.Mesh(this.railGeometry, this.railMaterial);
    this.railMesh.castShadow = true;
    return this.add(this.railMesh);
  };

  /*
  # Spine Drawing
  */


  Track.prototype.prepareSpine = function() {
    this.spineGeometry = new THREE.Geometry;
    if (this.spineShapeNeedsUpdate && this.spineShape) {
      this.spineShapeNeedsUpdate = false;
      this._spineVertices = this.spineShape.extractPoints(1).shape;
      this._spineFaces = THREE.Shape.Utils.triangulateShape(this._spineVertices, []);
    }
  };

  Track.prototype.spineStep = function(pos, normal, binormal) {
    if (!this.spineShape) {
      return;
    }
    return this._extrudeVertices(this._spineVertices, this.spineGeometry.vertices, pos, normal, binormal);
  };

  Track.prototype.finalizeSpine = function(spineSteps) {
    this._joinFaces(this._spineVertices, this._spineFaces, this.spineGeometry, spineSteps, 0, this.spineGeometry.vertices.length - this._spineVertices.length);
    this.spineGeometry.computeCentroids();
    this.spineGeometry.computeFaceNormals();
    this.spineMesh = new THREE.Mesh(this.spineGeometry, this.spineMaterial);
    this.spineMesh.castShadow = true;
    return this.add(this.spineMesh);
  };

  /*
  # Tie Drawing
  */


  Track.prototype.prepareTies = function() {
    this.tieGeometry = new THREE.Geometry;
    if (this.tieShapeNeedsUpdate && this.tieShape) {
      this.tieShapeNeedsUpdate = false;
      this._tieVertices = this.tieShape.extractPoints(1).shape;
      this._tieFaces = THREE.Shape.Utils.triangulateShape(this._tieVertices, []);
      if (this.extendedTieShape) {
        this._extendedTieVertices = this.extendedTieShape.extractPoints(1).shape;
        this._extendedTieFaces = THREE.Shape.Utils.triangulateShape(this._extendedTieVertices, []);
      }
    }
  };

  _cross = new THREE.Vector3;

  Track.prototype.tieStep = function(pos, normal, binormal, useExtended) {
    var faces, offset, vertices;
    if (!this.tieShape) {
      return;
    }
    offset = this.tieGeometry.vertices.length;
    vertices = useExtended ? this._extendedTieVertices : this._tieVertices;
    faces = useExtended ? this._extendedTieFaces : this._tieFaces;
    _cross.crossVectors(normal, binormal).normalize();
    _cross.setLength(this.tieDepth / 2).negate();
    this._extrudeVertices(vertices, this.tieGeometry.vertices, pos, normal, binormal, _cross);
    _cross.negate();
    this._extrudeVertices(vertices, this.tieGeometry.vertices, pos, normal, binormal, _cross);
    return this._joinFaces(vertices, faces, this.tieGeometry, 1, offset, vertices.length, true);
  };

  Track.prototype.finalizeTies = function(tieSteps) {
    this.tieGeometry.computeCentroids();
    this.tieGeometry.computeFaceNormals();
    this.tieMesh = new THREE.Mesh(this.tieGeometry, this.tieMaterial);
    this.tieMesh.castShadow = true;
    return this.add(this.tieMesh);
  };

  /*
  # Helpers
  */


  _normal = new THREE.Vector3;

  _binormal = new THREE.Vector3;

  _pos = new THREE.Vector3;

  Track.prototype._extrudeVertices = function(template, target, pos, normal, binormal, extra) {
    var vertex, _i, _len;
    for (_i = 0, _len = template.length; _i < _len; _i++) {
      vertex = template[_i];
      _normal.copy(normal).multiplyScalar(vertex.x);
      _binormal.copy(binormal).multiplyScalar(vertex.y);
      _pos.copy(pos).add(_normal).add(_binormal);
      if (extra) {
        _pos.add(extra);
      }
      target.push(_pos.clone());
    }
  };

  Track.prototype._joinFaces = function(vertices, template, target, totalSteps, startOffset, endOffset, flipOutside) {
    var a, b, c, d, face, i, j, k, s, slen1, slen2, uvs, _i, _j, _len, _ref;
    for (_i = 0, _len = template.length; _i < _len; _i++) {
      face = template[_i];
      a = face[flipOutside ? 2 : 0] + startOffset;
      b = face[1] + startOffset;
      c = face[flipOutside ? 0 : 2] + startOffset;
      target.faces.push(new THREE.Face3(a, b, c, null, null, null));
      target.faceVertexUvs[0].push(uvgen.generateBottomUV(target, null, null, a, b, c));
      a = face[flipOutside ? 0 : 2] + startOffset + endOffset;
      b = face[1] + startOffset + endOffset;
      c = face[flipOutside ? 2 : 0] + startOffset + endOffset;
      target.faces.push(new THREE.Face3(a, b, c, null, null, null));
      target.faceVertexUvs[0].push(uvgen.generateTopUV(target, null, null, a, b, c));
    }
    i = vertices.length;
    while (--i >= 0) {
      j = i;
      k = i - 1;
      if (k < 0) {
        k = vertices.length - 1;
      }
      for (s = _j = 0, _ref = totalSteps - 1; 0 <= _ref ? _j <= _ref : _j >= _ref; s = 0 <= _ref ? ++_j : --_j) {
        slen1 = vertices.length * s;
        slen2 = vertices.length * (s + 1);
        a = j + slen1 + startOffset;
        b = k + slen1 + startOffset;
        c = k + slen2 + startOffset;
        d = j + slen2 + startOffset;
        target.faces.push(new THREE.Face3(d, b, a, null, null, null));
        target.faces.push(new THREE.Face3(d, c, b, null, null, null));
        uvs = uvgen.generateSideWallUV(target, null, null, null, a, b, c, d, s, totalSteps, j, k);
        target.faceVertexUvs[0].push([uvs[0], uvs[1], uvs[3]]);
        target.faceVertexUvs[0].push([uvs[1], uvs[2], uvs[3]]);
      }
    }
  };

  return Track;

})(THREE.Object3D);
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
        car.castShadow = true;
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
        this.selected.line.geometry.verticesNeedUpdate = true;
        oppositeHandle = this.selectedHandle === this.selected.left ? this.selected.right : this.selected.left;
        oppositeHandle.position.copy(this.selectedHandle.position).negate();
      }
    }
    if (this.selected || force) {
      this.spline.rebuild();
      if (!this.rerenderTimeout) {
        this.rerenderTimeout = setTimeout(function() {
          localStorage.setItem('track', JSON.stringify(_this.spline));
          _this.rerenderTimeout = null;
          _this.renderCurve();
          return LW.track.rebuild();
        }, 10);
      }
    }
  };

  EditTrack.prototype.pick = function(pos, objects) {
    var camera, ray, vector, x, y;
    camera = LW.controls.camera;
    x = pos.x, y = pos.y;
    if (LW.renderer.useQuadView) {
      if (x > 0.5) {
        x -= 0.5;
      }
      if (y > 0.5) {
        y -= 0.5;
      }
      vector = new THREE.Vector3(x * 4 - 1, -y * 4 + 1, 0.5);
    } else {
      vector = new THREE.Vector3(x * 2 - 1, -y * 2 + 1, 0.5);
    }
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
    var i, lastNode, node, point, _i, _len, _ref;
    this.clear();
    this.controlPoints = [];
    lastNode = null;
    if (LW.onRideCamera) {
      return;
    }
    _ref = this.spline.points;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      point = _ref[i];
      node = new LW.PointEditor(point);
      this.add(node);
      this.controlPoints.push(node);
    }
    return this.renderCurve();
  };

  EditTrack.prototype.renderCurve = function() {
    var geo, mat;
    if (this.line) {
      this.remove(this.line);
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
  };

  return EditTrack;

})(THREE.Object3D);

LW.PointEditor = (function(_super) {
  __extends(PointEditor, _super);

  function PointEditor(point) {
    var controlMaterial, geo, lineGeo, pointMaterial;
    this.point = point;
    geo = new THREE.SphereGeometry(1);
    controlMaterial = new THREE.MeshLambertMaterial({
      color: CONTROL_COLOR
    });
    pointMaterial = new THREE.MeshLambertMaterial({
      color: POINT_COLOR
    });
    PointEditor.__super__.constructor.call(this, geo, controlMaterial);
    this.position = point.position;
    this.isControl = true;
    this.left = new THREE.Mesh(geo, pointMaterial);
    this.left.position = point.left;
    this.left.visible = false;
    this.add(this.left);
    this.right = new THREE.Mesh(geo, pointMaterial);
    this.right.position = point.right;
    this.right.visible = false;
    this.add(this.right);
    lineGeo = new THREE.Geometry;
    lineGeo.vertices.push(point.left);
    lineGeo.vertices.push(new THREE.Vector3);
    lineGeo.vertices.push(point.right);
    this.line = new THREE.Line(lineGeo, new THREE.LineBasicMaterial({
      color: POINT_COLOR,
      linewidth: 4
    }));
    this.line.visible = false;
    this.add(this.line);
  }

  PointEditor.prototype.select = function(selected) {
    var _ref, _ref1, _ref2;
    this.material.color.setHex(selected ? SELECTED_COLOR : CONTROL_COLOR);
    if ((_ref = this.left) != null) {
      _ref.visible = selected;
    }
    if ((_ref1 = this.right) != null) {
      _ref1.visible = selected;
    }
    return (_ref2 = this.line) != null ? _ref2.visible = selected : void 0;
  };

  return PointEditor;

})(THREE.Mesh);
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.BMTrack = (function(_super) {
  var boxShape, boxSize, offsetX, offsetY, padding, radius, tieShape;

  __extends(BMTrack, _super);

  boxSize = 2;

  offsetY = -3;

  boxShape = new THREE.Shape;

  boxShape.moveTo(-boxSize, -boxSize + offsetY);

  boxShape.lineTo(-boxSize, boxSize + offsetY);

  boxShape.lineTo(boxSize, boxSize + offsetY);

  boxShape.lineTo(boxSize, -boxSize + offsetY);

  boxShape.lineTo(-boxSize, -boxSize + offsetY);

  BMTrack.prototype.spineShape = boxShape;

  BMTrack.prototype.spineDivisionLength = 7;

  radius = 0.5;

  offsetX = boxSize + 2;

  offsetY = 0;

  padding = boxSize / 4;

  tieShape = new THREE.Shape;

  tieShape.moveTo(boxSize, boxSize - 3 - padding);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75);

  tieShape.lineTo(boxSize / 2, boxSize - 2.5);

  tieShape.lineTo(-boxSize / 2, boxSize - 2.5);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY);

  tieShape.lineTo(-boxSize, boxSize - 3 - padding);

  BMTrack.prototype.tieShape = tieShape;

  tieShape = new THREE.Shape;

  tieShape.moveTo(boxSize + padding, boxSize - 3 - padding);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY + radius * 0.75);

  tieShape.lineTo(boxSize / 2, boxSize - 2.5);

  tieShape.lineTo(-boxSize / 2, boxSize - 2.5);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY + radius * 0.75);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY);

  tieShape.lineTo(-boxSize - padding, boxSize - 3 - padding);

  tieShape.lineTo(-boxSize - padding, -boxSize - 3 - padding);

  tieShape.lineTo(boxSize + padding, -boxSize - 3 - padding);

  BMTrack.prototype.extendedTieShape = tieShape;

  BMTrack.prototype.tieDepth = 0.4;

  BMTrack.prototype.railRadius = radius;

  BMTrack.prototype.railDistance = offsetX - radius;

  function BMTrack() {
    BMTrack.__super__.constructor.apply(this, arguments);
    this.spineMaterial = new THREE.MeshPhongMaterial({
      color: 0xff0000,
      ambient: 0x090909,
      specular: 0x333333,
      shininess: 30
    });
    this.tieMaterial = this.spineMaterial.clone();
    this.railMaterial = this.spineMaterial.clone();
    this.materials = [this.spineMaterial, this.tieMaterial, this.railMaterial];
  }

  return BMTrack;

})(LW.Track);
