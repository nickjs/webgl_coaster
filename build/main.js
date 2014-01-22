var __hasProp = {}.hasOwnProperty;

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

THREE.Vector4.prototype.copy = function(v) {
  this.x = v.x;
  this.y = v.y;
  this.z = v.z;
  if (v.w != null) {
    this.w = v.w;
  }
  if (this.w == null) {
    return this.w = 1;
  }
};

window.LW = {
  init: function() {
    var controls, renderer, terrain,
      _this = this;
    renderer = this.renderer = new LW.Renderer(document.body);
    terrain = new LW.Terrain(renderer);
    this.edit = new LW.EditTrack;
    renderer.scene.add(this.edit);
    this.track = new LW.BMInvertedTrack;
    renderer.scene.add(this.track);
    this.train = new LW.Train(this.track, {
      numberOfCars: 4
    });
    this.train.start();
    renderer.scene.add(this.train);
    this.gui = new LW.GUIController;
    controls = this.controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement);
    controls.center.copy(this.edit.position);
    controls.addEventListener('change', function() {
      var _ref, _ref1;
      return (_ref = _this.edit) != null ? (_ref1 = _ref.transformControl) != null ? _ref1.update() : void 0 : void 0;
    });
    return renderer.render();
  },
  mixin: function(context, mixin) {
    var key, val, _results;
    _results = [];
    for (key in mixin) {
      if (!__hasProp.call(mixin, key)) continue;
      val = mixin[key];
      _results.push(context[key] = val);
    }
    return _results;
  }
};

window.onload = function() {
  return LW.init();
};
LW.Observable = {
  observe: function(key, callback) {
    var _base;
    this._observers || (this._observers = {});
    (_base = this._observers)[key] || (_base[key] = []);
    return this._observers[key].push(callback);
  },
  fire: function(key, value, oldValue) {
    var callback, callbacks, _i, _len, _ref, _results;
    callbacks = (_ref = this._observers) != null ? _ref[key] : void 0;
    if (callbacks != null ? callbacks.length : void 0) {
      _results = [];
      for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
        callback = callbacks[_i];
        _results.push(callback(value, oldValue));
      }
      return _results;
    }
  }
};
var oldUpdateDisplay,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty;

LW.GUIController = (function() {
  function GUIController() {
    this.changeOnRideCamera = __bind(this.changeOnRideCamera, this);
    this.changeVertex = __bind(this.changeVertex, this);
    this.vertexChanged = __bind(this.vertexChanged, this);
    var key, val;
    this.gui = new dat.GUI();
    this.modelProxy = new LW.TrackModel;
    this.segmentProxy = new LW.TrackModel;
    this.vertexProxy = new THREE.Vector4;
    this.gui.add(LW.edit, 'mode', (function() {
      var _ref, _results;
      _ref = LW.EditTrack.MODES;
      _results = [];
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        val = _ref[key];
        _results.push(val);
      }
      return _results;
    })()).name("tool");
    this.vertexFolder = this.gui.addFolder("Vertex Properties");
    this.vertexFolder.add(this.vertexProxy, 'x', -250, 250).onChange(this.changeVertex);
    this.vertexFolder.add(this.vertexProxy, 'y', 0, 500).onChange(this.changeVertex);
    this.vertexFolder.add(this.vertexProxy, 'z', -250, 250).onChange(this.changeVertex);
    this.vertexFolder.add(this.vertexProxy, 'w', 0, Math.PI).name("weight").onChange(this.changeVertex);
    LW.edit.observe('vertexChanged', this.vertexChanged);
    this.styleFolder = this.gui.addFolder("Style Properties");
    this.styleFolder.addColor(this.segmentProxy, 'spineColor').name("spine color").onChange(this.changeColor('spine'));
    this.styleFolder.addColor(this.segmentProxy, 'tieColor').name("tie color").onChange(this.changeColor('tie'));
    this.styleFolder.addColor(this.segmentProxy, 'railColor').name("rail color").onChange(this.changeColor('rail'));
    this.styleFolder.addColor(this.segmentProxy, 'wireframeColor').name("wireframe color").onChange(this.changeColor('wireframe'));
    this.viewFolder = this.gui.addFolder("View Properties");
    this.viewFolder.add(LW.renderer, 'showFPS').name("show FPS").onChange(this.changeShowFPS);
    this.viewFolder.add(LW.renderer, 'useQuadView').name("quad view");
    this.viewFolder.add(this.modelProxy, 'onRideCamera').name("ride camera").onChange(this.changeOnRideCamera);
    this.viewFolder.add(this.modelProxy, 'forceWireframe').name("force wireframe").onChange(this.changeForceWireframe);
    this.viewFolder.add(this.modelProxy, 'debugNormals').name("show normals").onChange(this.changeDebugNormals);
    this.addSaveBar();
    this.loadTracks();
  }

  GUIController.prototype.updateFolder = function(folderKey, openFolder) {
    var controller, _i, _len, _ref;
    _ref = this[folderKey].__controllers;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      controller = _ref[_i];
      controller.updateDisplay();
    }
    return this[folderKey][openFolder ? 'open' : 'close']();
  };

  GUIController.prototype.vertexChanged = function(vertex) {
    if (vertex) {
      this.vertexProxy.copy(vertex.point);
    } else {
      this.vertexProxy.set(0, 0, 0);
    }
    return this.updateFolder('vertexFolder', !!vertex);
  };

  GUIController.prototype.changeVertex = function() {
    LW.edit.transformControl.update();
    LW.edit.selected.position.copy(this.vertexProxy);
    LW.edit.selected.point.copy(this.vertexProxy);
    return LW.edit.changed();
  };

  GUIController.prototype.changeColor = function(key) {
    return function(value) {
      var _ref;
      LW.model["" + key + "Color"] = value;
      return (_ref = LW.track) != null ? _ref.updateMaterials() : void 0;
    };
  };

  GUIController.prototype.changeShowFPS = function(value) {
    var node;
    node = LW.renderer.stats.domElement;
    if (value) {
      return LW.renderer.domElement.parentNode.appendChild(node);
    } else {
      return node.parentNode.removeChild(node);
    }
  };

  GUIController.prototype.changeOnRideCamera = function(value) {
    LW.model.onRideCamera = value;
    if (value) {
      this.oldCamPos = LW.renderer.camera.position.clone();
      this.oldCamRot = LW.renderer.camera.rotation.clone();
      return LW.renderer.scene.remove(LW.edit);
    } else {
      this.oldCamPos || (this.oldCamPos = LW.renderer.defaultCamPos);
      this.oldCamRot || (this.oldCamRot = LW.renderer.defaultCamRot);
      LW.renderer.camera.position.copy(this.oldCamPos);
      LW.renderer.camera.rotation.copy(this.oldCamRot);
      LW.renderer.scene.add(LW.edit);
      return LW.edit.rebuild();
    }
  };

  GUIController.prototype.changeForceWireframe = function(value) {
    var _ref, _ref1, _ref2, _ref3;
    LW.model.forceWireframe = value;
    if (value) {
      if ((_ref = LW.track) != null) {
        _ref.wireframe = true;
      }
    } else {
      if ((_ref1 = LW.track) != null) {
        _ref1.wireframe = !!((_ref2 = LW.edit) != null ? _ref2.selected : void 0);
      }
    }
    return (_ref3 = LW.track) != null ? _ref3.rebuild() : void 0;
  };

  GUIController.prototype.changeDebugNormals = function(value) {
    var _ref;
    LW.model.debugNormals = value;
    return (_ref = LW.track) != null ? _ref.rebuild() : void 0;
  };

  GUIController.prototype.newTrack = function() {
    var track;
    this._addTrackToDropdown("Untitled");
    track = new LW.TrackModel([new THREE.Vector4(-100, 20, 0, 1), new THREE.Vector4(-20, 20, 0, 1), new THREE.Vector4(20, 30, 0, 1), new THREE.Vector4(60, 20, 0, 1), new THREE.Vector4(100, 0, 0, 1), new THREE.Vector4(200, 0, 0, 1), new THREE.Vector4(250, 60, 0, 1)]);
    return this.loadTrack(track);
  };

  GUIController.prototype.saveTrack = function() {
    var name, tracks;
    if (!LW.model.name) {
      name = prompt("What do you want to call this track?");
      if (!name) {
        return;
      }
      tracks = JSON.parse(localStorage.getItem('tracks')) || [];
      if (tracks.indexOf(name) !== -1) {
        if (!confirm("A track with name " + name + " already exists. Are you sure you want to overwrite it?")) {
          return this.saveTrack();
        }
      }
      LW.model.name = name;
      tracks.push(name);
      localStorage.setItem('tracks', JSON.stringify(tracks));
      this._addTrackToDropdown(name);
    }
    return localStorage.setItem("track." + LW.model.name, JSON.stringify(LW.model.toJSON()));
  };

  GUIController.prototype.loadTrack = function(track) {
    var json, _ref, _ref1, _ref2;
    if (typeof track === 'string') {
      json = JSON.parse(localStorage.getItem("track." + track));
      track = new LW.TrackModel;
      track.fromJSON(json);
    }
    LW.model = track;
    this.modelProxy.fromJSON(track.toJSON());
    this.segmentProxy.fromJSON(track.toJSON());
    this.updateFolder('viewFolder', false);
    if ((_ref = LW.edit) != null) {
      _ref.rebuild();
    }
    if ((_ref1 = LW.track) != null) {
      _ref1.rebuild();
    }
    return (_ref2 = LW.train) != null ? _ref2.start() : void 0;
  };

  GUIController.prototype.loadTracks = function() {
    var e, track, tracks, _i, _len;
    this.dropdown.innerHTML = '';
    try {
      tracks = JSON.parse(localStorage.getItem('tracks'));
      if (tracks != null ? tracks.length : void 0) {
        for (_i = 0, _len = tracks.length; _i < _len; _i++) {
          track = tracks[_i];
          this._addTrackToDropdown(track);
        }
        return this.loadTrack(track);
      } else {
        return this.newTrack();
      }
    } catch (_error) {
      e = _error;
      console.log(e);
      console.log(e.stack);
      alert("Well, seems like I've gone and changed the track format again. Unfortunately I'll have to clear all your tracks now. Sorry mate!");
      localStorage.clear();
      return this.loadTracks();
    }
  };

  GUIController.prototype.clearAllTracks = function() {
    if (confirm("This will remove all your tracks. Are you sure you wish to do this?")) {
      localStorage.clear();
      return this.loadTracks();
    }
  };

  GUIController.prototype.addSaveBar = function() {
    var clearButton, gears, newButton, saveButton, saveRow,
      _this = this;
    saveRow = document.createElement('li');
    saveRow.classList.add('save-row');
    saveRow.style.width = '245px';
    this.gui.__ul.insertBefore(saveRow, this.gui.__ul.firstChild);
    this.gui.domElement.classList.add('has-save');
    this.dropdown = document.createElement('select');
    this.dropdown.addEventListener('change', function() {
      return _this.loadTrack(_this.dropdown.value);
    });
    saveRow.appendChild(this.dropdown);
    newButton = document.createElement('span');
    newButton.innerHTML = 'New';
    newButton.className = 'button new';
    newButton.addEventListener('click', function() {
      return _this.newTrack();
    });
    saveRow.appendChild(newButton);
    saveButton = document.createElement('span');
    saveButton.innerHTML = 'Save';
    saveButton.className = 'button save';
    saveButton.addEventListener('click', function() {
      return _this.saveTrack();
    });
    saveRow.appendChild(saveButton);
    clearButton = document.createElement('span');
    clearButton.innerHTML = 'Reset';
    clearButton.className = 'button clear';
    clearButton.addEventListener('click', function() {
      return _this.clearAllTracks();
    });
    saveRow.appendChild(clearButton);
    gears = document.createElement('span');
    gears.innerHTML = '&nbsp;';
    gears.className = 'button gears';
    return saveRow.appendChild(gears);
  };

  GUIController.prototype._addTrackToDropdown = function(name) {
    var option;
    option = document.createElement('option');
    option.innerHTML = name;
    option.value = name;
    option.selected = true;
    return this.dropdown.appendChild(option);
  };

  return GUIController;

})();

oldUpdateDisplay = dat.controllers.BooleanController.prototype.updateDisplay;

dat.controllers.BooleanController.prototype.updateDisplay = function() {
  this.__prev = this.getValue();
  return oldUpdateDisplay.call(this);
};
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

LW.Renderer = (function() {
  Renderer.prototype.showFPS = true;

  Renderer.prototype.useQuadView = false;

  Renderer.prototype.defaultCamPos = new THREE.Vector3(0, 0, 60);

  Renderer.prototype.defaultCamRot = new THREE.Euler(0, 0, 0, 'XYZ');

  function Renderer(container) {
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
    container.appendChild(this.domElement);
    this.stats = new Stats;
    if (this.showFPS) {
      container.appendChild(this.stats.domElement);
    }
    this.scene = new THREE.Scene;
    this.clock = new THREE.Clock;
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.01, 10000);
    this.camera.shouldRotate = true;
    this.camera.position.copy(this.defaultCamPos);
    this.camera.rotation.copy(this.defaultCamRot);
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
    var SCREEN_HEIGHT, SCREEN_WIDTH, _ref;
    if ((_ref = LW.train) != null) {
      _ref.simulate(this.clock.getDelta());
    }
    SCREEN_WIDTH = window.innerWidth * this.renderer.devicePixelRatio;
    SCREEN_HEIGHT = window.innerHeight * this.renderer.devicePixelRatio;
    this.renderer.clear();
    if (this.useQuadView) {
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
    this.renderer.render(this.scene, this.camera);
    this.stats.update();
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

LW.TrackMesh = (function(_super) {
  var UP, uvgen, _binormal, _cross, _normal, _pos;

  __extends(TrackMesh, _super);

  TrackMesh.prototype.railRadius = 1;

  TrackMesh.prototype.railDistance = 2;

  TrackMesh.prototype.railRadialSegments = 8;

  TrackMesh.prototype.numberOfRails = 2;

  TrackMesh.prototype.spineShape = null;

  TrackMesh.prototype.spineDivisionLength = 5;

  TrackMesh.prototype.spineShapeNeedsUpdate = true;

  TrackMesh.prototype.tieShape = null;

  TrackMesh.prototype.tieDepth = 1;

  TrackMesh.prototype.tieShapeNeedsUpdate = true;

  TrackMesh.prototype.wireframe = false;

  function TrackMesh(options) {
    TrackMesh.__super__.constructor.call(this);
    LW.mixin(this, options);
  }

  UP = new THREE.Vector3(0, 1, 0);

  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator;

  TrackMesh.prototype.updateMaterials = function() {
    this.wireframeMaterial || (this.wireframeMaterial = new THREE.LineBasicMaterial({
      color: 0x0000ff,
      linewidth: 2
    }));
    this.spineMaterial || (this.spineMaterial = new THREE.MeshPhongMaterial({
      color: 0xff0000,
      ambient: 0x090909,
      specular: 0x333333,
      shininess: 30
    }));
    this.tieMaterial || (this.tieMaterial = this.spineMaterial.clone());
    this.railMaterial || (this.railMaterial = this.spineMaterial.clone());
    this.wireframeMaterial.color.setStyle(this.model.wireframeColor);
    this.spineMaterial.color.setStyle(this.model.spineColor);
    this.tieMaterial.color.setStyle(this.model.tieColor);
    return this.railMaterial.color.setStyle(this.model.railColor);
  };

  TrackMesh.prototype.rebuild = function() {
    var bank, binormal, i, lastSpinePos, normal, pos, spineSteps, tangent, totalLength, u, _i;
    this.clear();
    if (this.model !== LW.model) {
      this.model = LW.model;
    }
    if (!this.model) {
      return;
    }
    if (this.model.forceWireframe) {
      this.wireframe = true;
    }
    this.updateMaterials();
    this.prepareRails();
    this.prepareTies();
    this.prepareSpine();
    totalLength = Math.ceil(this.model.spline.getLength()) * 10;
    spineSteps = 0;
    binormal = new THREE.Vector3;
    normal = new THREE.Vector3;
    for (i = _i = 0; 0 <= totalLength ? _i <= totalLength : _i >= totalLength; i = 0 <= totalLength ? ++_i : --_i) {
      u = i / totalLength;
      pos = this.model.spline.getPointAt(u);
      tangent = this.model.spline.getTangentAt(u).normalize();
      bank = THREE.Math.degToRad(this.model.getBankAt(u));
      binormal.copy(UP).applyAxisAngle(tangent, bank);
      normal.crossVectors(tangent, binormal).normalize();
      binormal.crossVectors(normal, tangent).normalize();
      if (!lastSpinePos || lastSpinePos.distanceTo(pos) >= this.spineDivisionLength) {
        this.tieStep(pos, normal, binormal, spineSteps % 7 === 0);
        this.spineStep(pos, normal, binormal);
        if (this.model.debugNormals) {
          this.add(new THREE.ArrowHelper(normal, pos, 5, 0x00ff00));
          this.add(new THREE.ArrowHelper(binormal, pos, 5, 0x0000ff));
        }
        spineSteps++;
        lastSpinePos = pos;
      }
      this.railStep(pos, normal, binormal);
    }
    this.spineStep(pos, normal, binormal);
    this.finalizeRails(totalLength);
    this.finalizeTies(spineSteps);
    return this.finalizeSpine(spineSteps);
  };

  /*
  # Rail Drawing
  */


  TrackMesh.prototype.prepareRails = function() {
    var i, _i, _j, _ref, _ref1, _results, _results1;
    if (this.wireframe) {
      this.railGeometries = [];
      _results = [];
      for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push(this.railGeometries.push(new THREE.Geometry));
      }
      return _results;
    } else {
      this.railGeometry = new THREE.Geometry;
      this._railGrids = [];
      _results1 = [];
      for (i = _j = 0, _ref1 = this.numberOfRails - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
        _results1.push(this._railGrids.push([]));
      }
      return _results1;
    }
  };

  TrackMesh.prototype.railStep = function(pos, normal, binormal) {
    var cx, cy, distance, grid, i, j, v, xDistance, yDistance, _i, _j, _ref, _ref1, _results;
    if (!this.numberOfRails) {
      return;
    }
    _results = [];
    for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (this.wireframe) {
        distance = this.railDistance;
        if (i % 2 === 0) {
          distance = -distance;
        }
        _results.push(this._extrudeVertices([new THREE.Vector3(distance, 0)], this.railGeometries[i].vertices, pos, normal, binormal));
      } else {
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
    }
    return _results;
  };

  TrackMesh.prototype.finalizeRails = function(steps) {
    var a, b, c, d, i, ip, j, jp, n, uva, uvb, uvc, uvd, _i, _j, _k, _l, _ref, _ref1, _ref2, _ref3, _results;
    if (this.wireframe) {
      _results = [];
      for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push(this.add(new THREE.Line(this.railGeometries[i], this.wireframeMaterial)));
      }
      return _results;
    } else {
      for (n = _j = 0, _ref1 = this.numberOfRails - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; n = 0 <= _ref1 ? ++_j : --_j) {
        for (i = _k = 0, _ref2 = steps - 1; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; i = 0 <= _ref2 ? ++_k : --_k) {
          for (j = _l = 0, _ref3 = this.railRadialSegments; 0 <= _ref3 ? _l <= _ref3 : _l >= _ref3; j = 0 <= _ref3 ? ++_l : --_l) {
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
    }
  };

  /*
  # Spine Drawing
  */


  TrackMesh.prototype.prepareSpine = function() {
    this.spineGeometry = new THREE.Geometry;
    if (this.wireframe) {
      return;
    }
    if (this.spineShapeNeedsUpdate && this.spineShape) {
      this.spineShapeNeedsUpdate = false;
      this._spineVertices = this.spineShape.extractPoints(1).shape;
      this._spineFaces = THREE.Shape.Utils.triangulateShape(this._spineVertices, []);
    }
  };

  TrackMesh.prototype.spineStep = function(pos, normal, binormal) {
    if (this.wireframe) {
      return this._extrudeVertices(this.wireframeSpine, this.spineGeometry.vertices, pos, normal, binormal);
    } else {
      if (!this.spineShape) {
        return;
      }
      return this._extrudeVertices(this._spineVertices, this.spineGeometry.vertices, pos, normal, binormal);
    }
  };

  TrackMesh.prototype.finalizeSpine = function(spineSteps) {
    if (this.wireframe) {
      this.spineMesh = new THREE.Line(this.spineGeometry, this.wireframeMaterial);
    } else {
      this._joinFaces(this._spineVertices, this._spineFaces, this.spineGeometry, spineSteps, 0, this.spineGeometry.vertices.length - this._spineVertices.length);
      this.spineGeometry.computeCentroids();
      this.spineGeometry.computeFaceNormals();
      this.spineMesh = new THREE.Mesh(this.spineGeometry, this.spineMaterial);
      this.spineMesh.castShadow = true;
    }
    return this.add(this.spineMesh);
  };

  /*
  # Tie Drawing
  */


  TrackMesh.prototype.prepareTies = function() {
    this.tieGeometry = new THREE.Geometry;
    if (this.wireframe) {
      return;
    }
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

  TrackMesh.prototype.tieStep = function(pos, normal, binormal, useExtended) {
    var faces, offset, vertices;
    if (this.wireframe) {
      return this._extrudeVertices(this.wireframeTies, this.tieGeometry.vertices, pos, normal, binormal);
    } else {
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
    }
  };

  TrackMesh.prototype.finalizeTies = function(tieSteps) {
    if (this.wireframe) {
      this.tieMesh = new THREE.Line(this.tieGeometry, this.wireframeMaterial, THREE.LinePieces);
    } else {
      this.tieGeometry.computeCentroids();
      this.tieGeometry.computeFaceNormals();
      this.tieMesh = new THREE.Mesh(this.tieGeometry, this.tieMaterial);
      this.tieMesh.castShadow = true;
    }
    return this.add(this.tieMesh);
  };

  /*
  # Helpers
  */


  _normal = new THREE.Vector3;

  _binormal = new THREE.Vector3;

  _pos = new THREE.Vector3;

  TrackMesh.prototype._extrudeVertices = function(template, target, pos, normal, binormal, extra) {
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

  TrackMesh.prototype._joinFaces = function(vertices, template, target, totalSteps, startOffset, endOffset, flipOutside) {
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

  return TrackMesh;

})(THREE.Object3D);
LW.TrackModel = (function() {
  TrackModel.prototype.name = "";

  TrackModel.prototype.points = null;

  TrackModel.prototype.spline = null;

  TrackModel.prototype.rollSpline = null;

  TrackModel.prototype.isConnected = false;

  TrackModel.prototype.onRideCamera = false;

  TrackModel.prototype.forceWireframe = false;

  TrackModel.prototype.debugNormals = false;

  TrackModel.prototype.spineColor = '#ff0000';

  TrackModel.prototype.tieColor = '#ff0000';

  TrackModel.prototype.railColor = '#ff0000';

  TrackModel.prototype.wireframeColor = '#0000ff';

  function TrackModel(points) {
    this.points = points;
    this.rollPoints = [new THREE.Vector2(0, 0), new THREE.Vector2(1, 0)];
    this.rebuild();
  }

  TrackModel.prototype.rebuild = function() {
    var i, knot, knots, p, _i, _len, _ref, _ref1;
    if (!(((_ref = this.points) != null ? _ref.length : void 0) > 1)) {
      return;
    }
    knots = [0, 0, 0, 0];
    _ref1 = this.points;
    for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
      p = _ref1[i];
      knot = (i + 1) / (this.points.length - 3);
      knots.push(THREE.Math.clamp(knot, 0, 1));
    }
    this.spline = new THREE.NURBSCurve(3, knots, this.points);
    return this.rollSpline = new THREE.SplineCurve(this.rollPoints);
  };

  TrackModel.prototype.positionOnSpline = function(seekingPos) {
    var currentPos, distance, i, totalLength, u, _i;
    totalLength = Math.ceil(this.spline.getLength()) * 10;
    for (i = _i = 0; 0 <= totalLength ? _i <= totalLength : _i >= totalLength; i = 0 <= totalLength ? ++_i : --_i) {
      u = i / totalLength;
      currentPos = this.spline.getPointAt(u);
      distance = currentPos.distanceTo(seekingPos);
      if (currentPos.distanceTo(seekingPos) <= 5) {
        return u;
      }
    }
  };

  TrackModel.prototype.addRollPoint = function(t, amount) {
    return this.rollPoints.push(new THREE.Vector2(t, amount));
  };

  TrackModel.prototype.getBankAt = function(t) {
    return this.rollSpline.getPoint(t).y;
  };

  TrackModel.prototype.toJSON = function() {
    return {
      name: this.name,
      isConnected: this.isConnected,
      points: this.points,
      rollPoints: this.rollPoints,
      onRideCamera: this.onRideCamera,
      forceWireframe: this.forceWireframe,
      debugNormals: this.debugNormals,
      spineColor: this.spineColor,
      tieColor: this.tieColor,
      railColor: this.railColor,
      wireframeColor: this.wireframeColor
    };
  };

  TrackModel.prototype.fromJSON = function(json) {
    var p;
    LW.mixin(this, json);
    this.points = (function() {
      var _i, _len, _ref, _results;
      _ref = json.points;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        _results.push(new THREE.Vector4(p.x, p.y, p.z, p.w));
      }
      return _results;
    })();
    this.rollPoints = (function() {
      var _i, _len, _ref, _results;
      _ref = json.rollPoints;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        _results.push(new THREE.Vector2(p.x, p.y));
      }
      return _results;
    })();
    return this.rebuild();
  };

  return TrackModel;

})();
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.Train = (function(_super) {
  var down, mat, up, zero;

  __extends(Train, _super);

  Train.prototype.velocity = 20;

  Train.prototype.initialVelocity = 20;

  Train.prototype.displacement = 0;

  Train.prototype.numberOfCars = 1;

  function Train(track, options) {
    var geo, loader, mat,
      _this = this;
    this.track = track;
    Train.__super__.constructor.call(this);
    LW.mixin(this, options);
    if (track != null ? track.carModel : void 0) {
      loader = new THREE.ColladaLoader;
      loader.load("resources/models/" + track.carModel, function(result) {
        var sizeVector;
        _this.carProto = result.scene.children[0];
        _this.carProto.scale.copy(track.carScale);
        _this.carRot = new THREE.Matrix4().makeRotationFromEuler(track.carRotation, 'XYZ');
        sizeVector = new THREE.Vector3;
        _this.carProto.traverse(function(child) {
          if (child instanceof THREE.Mesh) {
            child.geometry.computeBoundingBox();
            if (child.geometry.boundingBox.size(sizeVector).lengthSq() > 10000) {
              return child.castShadow = true;
            }
          }
        });
        return _this.rebuild();
      });
    } else {
      geo = new THREE.CubeGeometry(8, 8, 16);
      mat = new THREE.MeshLambertMaterial({
        color: 0xeeeeee
      });
      this.carProto = new THREE.Mesh(geo, mat);
      this.rebuild();
    }
  }

  Train.prototype.rebuild = function() {
    var car, i, _i, _ref, _results;
    this.clear();
    this.cars = [];
    if (this.numberOfCars && this.carProto) {
      _results = [];
      for (i = _i = 1, _ref = this.numberOfCars; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        car = this.carProto.clone();
        if (i === this.numberOfCars) {
          car.remove(car.getObjectByName('connector'));
        }
        this.cars.push(car);
        _results.push(this.add(car));
      }
      return _results;
    }
  };

  Train.prototype.start = function() {
    this.shouldSimulate = true;
    this.velocity = this.initialVelocity;
    this.displacement = 0;
    return this.rebuild();
  };

  Train.prototype.stop = function() {
    this.shouldSimulate = false;
    this.clear();
    return this.cars = [];
  };

  up = new THREE.Vector3(0, 1, 0);

  down = new THREE.Vector3(0, -1, 0);

  zero = new THREE.Vector3();

  mat = new THREE.Matrix4();

  Train.prototype.simulate = function(delta) {
    var a, alpha, bank, binormal, car, deltaPoint, desiredDistance, i, lastPos, model, normal, pos, tangent, _i, _len, _ref;
    if (!this.shouldSimulate || !this.cars.length || !(model = this.track.model)) {
      return;
    }
    if (this.lastTangent) {
      alpha = down.angleTo(this.lastTangent);
      a = 29.43 * Math.cos(alpha);
      this.velocity = this.velocity + a * delta;
    }
    this.displacement = this.displacement + this.velocity * delta;
    if (this.position === 0) {
      this.currentTime = 0;
    } else {
      this.currentTime = this.displacement / model.spline.getLength();
    }
    if (this.currentTime > 1) {
      this.currentTime = 0;
      this.displacement = 0;
    }
    lastPos = model.spline.getPointAt(this.currentTime);
    deltaPoint = this.currentTime;
    desiredDistance = this.track.carDistance;
    _ref = this.cars;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      car = _ref[i];
      pos = null;
      if (i > 0) {
        while (deltaPoint > 0) {
          pos = model.spline.getPointAt(deltaPoint);
          if (pos.distanceTo(lastPos) >= desiredDistance) {
            break;
          }
          deltaPoint -= 0.001;
          if (deltaPoint < 0) {
            deltaPoint = 0;
          }
        }
      } else {
        pos = lastPos;
      }
      if (pos) {
        lastPos = pos;
        tangent = model.spline.getTangentAt(deltaPoint).normalize();
        if (i === 0) {
          this.lastTangent = tangent;
        }
        bank = THREE.Math.degToRad(model.getBankAt(deltaPoint));
        binormal = up.clone().applyAxisAngle(tangent, bank);
        normal = tangent.clone().cross(binormal).normalize();
        binormal = normal.clone().cross(tangent).normalize();
        zero.set(0, 0, 0);
        mat.set(normal.x, binormal.x, -tangent.x, 0, normal.y, binormal.y, -tangent.y, 0, normal.z, binormal.z, -tangent.z, 0, 0, 0, 0, 1);
        if (i === 0 && model.onRideCamera) {
          LW.renderer.camera.position.copy(pos).add(this.track.onRideCameraOffset.clone().applyMatrix4(mat));
          LW.renderer.camera.rotation.setFromRotationMatrix(mat);
        }
        car.position.copy(pos).add(zero.applyMatrix4(mat));
        car.rotation.setFromRotationMatrix(mat.multiply(this.carRot));
      }
    }
  };

  return Train;

})(THREE.Object3D);
var CONTROL_COLOR, MODES, NODE_GEO, ROLL_NODE_COLOR, ROLL_NODE_GEO, SELECTED_COLOR,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CONTROL_COLOR = 0x0000ee;

ROLL_NODE_COLOR = 0x00ff00;

SELECTED_COLOR = 0xffffff;

NODE_GEO = new THREE.SphereGeometry(1);

ROLL_NODE_GEO = new THREE.CylinderGeometry(1, 2, 0.5);

MODES = {
  SELECT: 'select',
  ADD_ROLL: 'add roll'
};

LW.EditTrack = (function(_super) {
  __extends(EditTrack, _super);

  EditTrack.MODES = MODES;

  EditTrack.prototype.mode = MODES.SELECT;

  LW.mixin(EditTrack.prototype, LW.Observable);

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
      return (_ref = LW.controls) != null ? _ref.enabled = _this.transformControl.axis === void 0 : void 0;
    });
    this.transformControl.addEventListener('move', function() {
      return _this.changed();
    });
    LW.renderer.domElement.addEventListener('mousedown', this.onMouseDown, false);
    LW.renderer.domElement.addEventListener('mouseup', this.onMouseUp, false);
  }

  EditTrack.prototype.changed = function() {
    var _this = this;
    if (this.selected) {
      this.selected.point.copy(this.selected.position);
    }
    if (!this.rerenderTimeout) {
      this.rerenderTimeout = setTimeout(function() {
        var _ref;
        _this.rerenderTimeout = null;
        _this.renderCurve();
        return (_ref = LW.track) != null ? _ref.rebuild() : void 0;
      }, 50);
    }
    return this.fire('vertexChanged', this.selected);
  };

  EditTrack.prototype.pick = function(pos, objects, deep) {
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
      if (Array.isArray(objects)) {
        return this.raycaster.intersectObjects(objects, deep);
      } else {
        return this.raycaster.intersectObject(objects, deep);
      }
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
    var intersects, point, _ref, _ref1;
    if (!this.isMouseDown) {
      return;
    }
    this.mouseUp.x = event.clientX / window.innerWidth;
    this.mouseUp.y = event.clientY / window.innerHeight;
    if (this.mouseDown.distanceTo(this.mouseUp) === 0) {
      switch (this.mode) {
        case MODES.SELECT:
          intersects = this.pick(this.mouseUp, this.controlPoints);
          this.selectNode((_ref = intersects[0]) != null ? _ref.object : void 0);
          break;
        case MODES.ADD_ROLL:
          intersects = this.pick(this.mouseUp, LW.track, true);
          if (point = (_ref1 = intersects[0]) != null ? _ref1.point : void 0) {
            this.model.addRollPoint(this.model.positionOnSpline(point), Math.floor(Math.random() * 300));
            this.rebuild();
            LW.track.rebuild();
          }
      }
    }
    return this.isMouseDown = false;
  };

  EditTrack.prototype.selectNode = function(node) {
    var _ref, _ref1, _ref2, _ref3;
    if (this.selected === node) {
      return;
    }
    if ((_ref = this.selected) != null) {
      _ref.material.color.setHex(CONTROL_COLOR);
    }
    this.transformControl.detach();
    this.selected = node;
    if ((_ref1 = LW.track) != null) {
      _ref1.wireframe = !!node;
    }
    this.changed();
    if (node) {
      node.material.color.setHex(SELECTED_COLOR);
      this.transformControl.attach(node);
      return (_ref2 = LW.train) != null ? _ref2.stop() : void 0;
    } else {
      return (_ref3 = LW.train) != null ? _ref3.start() : void 0;
    }
  };

  EditTrack.prototype.rebuild = function() {
    var i, node, point, _i, _j, _len, _len1, _ref, _ref1;
    this.clear();
    this.controlPoints = [];
    if (this.model !== LW.model) {
      this.model = LW.model;
    }
    if (!this.model || this.model.onRideCamera) {
      return;
    }
    _ref = this.model.points;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      point = _ref[i];
      node = new THREE.Mesh(NODE_GEO, new THREE.MeshLambertMaterial({
        color: CONTROL_COLOR
      }));
      node.position.copy(point);
      node.point = point;
      this.add(node);
      this.controlPoints.push(node);
    }
    _ref1 = this.model.rollPoints;
    for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
      point = _ref1[i];
      node = new THREE.Mesh(ROLL_NODE_GEO, new THREE.MeshLambertMaterial({
        color: ROLL_NODE_COLOR
      }));
      node.position.copy(this.model.spline.getPointAt(point.x));
      node.point = point;
      this.add(node);
      this.controlPoints.push(node);
    }
    return this.renderCurve();
  };

  EditTrack.prototype.renderCurve = function() {
    var geo, mat, point, _i, _len, _ref;
    if (this.line) {
      this.remove(this.line);
    }
    if (this.model.onRideCamera) {
      return;
    }
    geo = new THREE.Geometry;
    _ref = this.model.points;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      point = _ref[_i];
      geo.vertices.push(point);
    }
    mat = new THREE.LineBasicMaterial({
      color: 0xff0000,
      linewidth: 2
    });
    this.line = new THREE.Line(geo, mat);
    this.add(this.line);
  };

  return EditTrack;

})(THREE.Object3D);
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

})(LW.TrackMesh);
var _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.BMInvertedTrack = (function(_super) {
  var boxShape, boxSize, offsetX, offsetY, padding, radius, railDistance, tieShape;

  __extends(BMInvertedTrack, _super);

  function BMInvertedTrack() {
    _ref = BMInvertedTrack.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  boxSize = 2;

  offsetY = 3;

  boxShape = new THREE.Shape;

  boxShape.moveTo(-boxSize, -boxSize + offsetY);

  boxShape.lineTo(-boxSize, boxSize + offsetY);

  boxShape.lineTo(boxSize, boxSize + offsetY);

  boxShape.lineTo(boxSize, -boxSize + offsetY);

  boxShape.lineTo(-boxSize, -boxSize + offsetY);

  BMInvertedTrack.prototype.spineShape = boxShape;

  BMInvertedTrack.prototype.spineDivisionLength = 7;

  radius = 0.5;

  offsetX = boxSize + 2;

  offsetY = radius * 0.75;

  padding = boxSize / 4;

  tieShape = new THREE.Shape;

  tieShape.moveTo(-boxSize, -boxSize + 3 + padding);

  tieShape.lineTo(-offsetX + radius * 1.5, 0);

  tieShape.lineTo(-offsetX + radius * 1.5, -offsetY);

  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(offsetX - radius * 1.5, -offsetY);

  tieShape.lineTo(offsetX - radius * 1.5, 0);

  tieShape.lineTo(boxSize, -boxSize + 3 + padding);

  BMInvertedTrack.prototype.tieShape = tieShape;

  tieShape = new THREE.Shape;

  tieShape.moveTo(-boxSize - padding, -boxSize + 3 + padding);

  tieShape.lineTo(-offsetX + radius * 1.5, 0);

  tieShape.lineTo(-offsetX + radius * 1.5, -offsetY);

  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(offsetX - radius * 1.5, -offsetY);

  tieShape.lineTo(offsetX - radius * 1.5, 0);

  tieShape.lineTo(boxSize + padding, -boxSize + 3 + padding);

  tieShape.lineTo(boxSize + padding, boxSize + 3 + padding);

  tieShape.lineTo(-boxSize - padding, boxSize + 3 + padding);

  BMInvertedTrack.prototype.extendedTieShape = tieShape;

  BMInvertedTrack.prototype.tieDepth = 0.4;

  BMInvertedTrack.prototype.railRadius = radius;

  BMInvertedTrack.prototype.railDistance = railDistance = offsetX - radius;

  offsetY = -boxSize + 3 + padding;

  BMInvertedTrack.prototype.wireframeSpine = [new THREE.Vector3(0, offsetY)];

  BMInvertedTrack.prototype.wireframeTies = [new THREE.Vector3(railDistance, 0), new THREE.Vector3(boxSize, offsetY), new THREE.Vector3(boxSize, offsetY), new THREE.Vector3(-boxSize, offsetY), new THREE.Vector3(-boxSize, offsetY), new THREE.Vector3(-railDistance, 0)];

  BMInvertedTrack.prototype.carModel = 'inverted.dae';

  BMInvertedTrack.prototype.carScale = new THREE.Vector3(0.0429, 0.0429, 0.037);

  BMInvertedTrack.prototype.carRotation = new THREE.Euler(-Math.PI * 0.5, 0, Math.PI, 'XYZ');

  BMInvertedTrack.prototype.carDistance = 9;

  BMInvertedTrack.prototype.onRideCameraOffset = new THREE.Vector3(2, -6, 0);

  return BMInvertedTrack;

})(LW.TrackMesh);
