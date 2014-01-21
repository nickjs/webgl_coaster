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
    var controls, renderer, terrain,
      _this = this;
    renderer = this.renderer = new LW.Renderer;
    document.body.appendChild(renderer.domElement);
    terrain = new LW.Terrain(renderer);
    this.edit = new LW.EditTrack();
    renderer.scene.add(this.edit);
    this.track = new LW.BMInvertedTrack();
    renderer.scene.add(this.track);
    this.train = new LW.Train(this.track, {
      numberOfCars: 4
    });
    renderer.scene.add(this.train);
    this.gui = new LW.GUIController;
    controls = this.controls = new THREE.EditorControls([renderer.topCamera, renderer.sideCamera, renderer.frontCamera, renderer.camera], renderer.domElement);
    controls.center.copy(this.edit.position);
    controls.addEventListener('change', function() {
      var _ref, _ref1;
      return (_ref = _this.edit) != null ? (_ref1 = _ref.transformControl) != null ? _ref1.update() : void 0 : void 0;
    });
    return renderer.render();
  }
};

window.onload = function() {
  return LW.init();
};
LW.GUIController = (function() {
  function GUIController() {
    this.gui = new dat.GUI();
    this.gui.addColor({
      color: '#ffffff'
    }, 'color');
    this.addSaveBar();
    this.loadTracks();
  }

  GUIController.prototype.newTrack = function() {
    var track;
    this._addTrackToDropdown("Untitled");
    track = new LW.TrackModel([new THREE.Vector4(-100, 20, 0, 1), new THREE.Vector4(-20, 20, 0, 1), new THREE.Vector4(20, 30, 0, 1), new THREE.Vector4(60, 20, 0, 1), new THREE.Vector4(100, 0, 0, 1), new THREE.Vector4(200, 0, 0, 1), new THREE.Vector4(250, 60, 0, 1)]);
    return this.loadTrack(track);
  };

  GUIController.prototype.saveTrack = function() {
    var name, tracks;
    if (!LW.spline.name) {
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
      LW.spline.name = name;
      tracks.push(name);
      localStorage.setItem('tracks', JSON.stringify(tracks));
      this._addTrackToDropdown(name);
    }
    return localStorage.setItem("track." + LW.spline.name, JSON.stringify(LW.spline.toJSON()));
  };

  GUIController.prototype.loadTrack = function(track) {
    var json, name, _ref, _ref1;
    if (typeof track === 'string') {
      name = track;
      json = JSON.parse(localStorage.getItem("track." + name));
      track = LW.BezierPath.fromJSON(json);
      track.name = name;
    }
    LW.model = track;
    if ((_ref = LW.edit) != null) {
      _ref.rebuild();
    }
    return (_ref1 = LW.track) != null ? _ref1.rebuild() : void 0;
  };

  GUIController.prototype.loadTracks = function() {
    var track, tracks, _i, _len;
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

/*
    @gui.save = => @saveTrack()
    @gui.saveAs = (name) => @newTrack(name)
    @gui.getSaveObject = => @getSaveObject()
    @gui.revert = @revert

    @tracks = {}
    @gui.load.remembered = @tracks
    @gui.remember(this)

    if trackNames = localStorage.getItem('tracks')
      for name in JSON.parse(trackNames)
        json = JSON.parse(localStorage.getItem("track.#{name}"))
        track = LW.BezierPath.fromJSON(json)
        track.name = name
        @tracks[name] = track
        @gui.addPresetOption(@gui, name, true)

      @setTrack(@tracks[name])
    else
      @newTrack('Untitled')

  saveTrack: ->
    localStorage.setItem("track.#{@track.name}", JSON.stringify(@track.toJSON()))

  newTrack: (name) ->
    track = new LW.BezierPath([
      new LW.Point(-25,0,0, -10,0,0, 10,0,0)
      new LW.Point(25,0,0, -10,0,0, 10,0,0)
    ])

    track.name = name
    @tracks[name] = track

    @gui.addPresetOption(@gui, name, true)

    names = (name for name of @tracks)
    localStorage.setItem('tracks', JSON.stringify(names))

    @setTrack(track)
    @saveTrack()

  getSaveObject: ->
    return @track.toJSON()

  setTrack: (track) ->
    @track = track

    LW.edit.rebuild(track)
    LW.track.rebuild(track)

    # file.add(this, '')

    # @gui = new dat.GUI()
    # @gui.add(@renderer, 'useQuadView')

    # file = @gui.addFolder('File')
    # file.add()

    # @trackFolder = @gui.addFolder('Track')
    # @trackFolder.open()

    # @trackFolder.addColor(spineColor: "#ff0000", 'spineColor').onChange (value) => @track.spineMaterial.color.setHex(value.replace('#', '0x'))
    # @trackFolder.addColor(tieColor: "#ff0000", 'tieColor').onChange (value) => @track.tieMaterial.color.setHex(value.replace('#', '0x'))
    # @trackFolder.addColor(railColor: "#ff0000", 'railColor').onChange (value) => @track.railMaterial.color.setHex(value.replace('#', '0x'))
    # @trackFolder.add(@track, 'forceWireframe')
    # @trackFolder.add(@track, 'debugNormals').onChange => @track.rebuild()
    # @trackFolder.add(@spline, 'isConnected').onChange (value) =>
    #   @spline.isConnected = value
    #   @edit.changed(true)

    # @trackFolder.add({addPoint: =>
    #   @spline.addControlPoint(@spline.getPoint(1).clone().add(new THREE.Vector3(40, 0, 0)))
    #   @edit.renderTrack()
    #   @track.rebuild()

    #   @edit.selectNode()
    # }, 'addPoint')

    # @onRideCamera = false
    # @trainFolder = @gui.addFolder('Train')
    # @trainFolder.open()

    # @trainFolder.addColor(color: '#ffffff', 'color').onChange (value) => @train.carMaterial.color.setHex(value.replace('#', '0x'))
    # @trainFolder.add(@train, 'movementSpeed', 0.01, 0.1)
    # @trainFolder.add(@train, 'numberOfCars', 0, 8).step(1).onChange (value) => @train.rebuild()
    # @trainFolder.add(this, 'onRideCamera').onChange (value) =>
    #   if value
    #     @oldCamPos = @renderer.camera.position.clone()
    #     @oldCamRot = @renderer.camera.rotation.clone()
    #     LW.renderer.scene.remove(@edit)
    #   else
    #     @renderer.camera.position.copy(@oldCamPos)
    #     @renderer.camera.rotation.copy(@oldCamRot)
    #     LW.renderer.scene.add(@edit)

    # @selected = {x: 0, y: 0, z: 0, bank: 0}
    # updateVector = (index, value) =>
    #   return if not @selected.node
    #   if index in ['x', 'y', 'z']
    #     @selected.node.position[index] = value
    #   else
    #     @selected.node.point[index] = value

    #   @edit.changed(true)

    # @pointFolder = @gui.addFolder('Point')
    # @pointFolder.add(@selected, 'x').onChange (value) -> updateVector('x', value)
    # @pointFolder.add(@selected, 'y').onChange (value) -> updateVector('y', value)
    # @pointFolder.add(@selected, 'z').onChange (value) -> updateVector('z', value)
    # @pointFolder.add(@selected, 'bank').onChange (value) -> updateVector('bank', value)
*/
;
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

  TrackMesh.prototype.debugNormals = false;

  function TrackMesh(options) {
    var key, value;
    TrackMesh.__super__.constructor.call(this);
    for (key in options) {
      value = options[key];
      this[key] = value;
    }
  }

  UP = new THREE.Vector3(0, 1, 0);

  uvgen = THREE.ExtrudeGeometry.WorldUVGenerator;

  TrackMesh.prototype.rebuild = function() {
    var bank, binormal, i, lastSpinePos, normal, pos, spineSteps, tangent, totalLength, u, _i;
    this.clear();
    if (this.model !== LW.model) {
      this.model = LW.model;
    }
    if (!this.model) {
      return;
    }
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
        spineSteps++;
        lastSpinePos = pos;
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


  TrackMesh.prototype.prepareRails = function() {
    var i, _i, _ref, _results;
    this.railGeometry = new THREE.Geometry;
    this._railGrids = [];
    _results = [];
    for (i = _i = 0, _ref = this.numberOfRails - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      _results.push(this._railGrids.push([]));
    }
    return _results;
  };

  TrackMesh.prototype.railStep = function(pos, normal, binormal) {
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

  TrackMesh.prototype.finalizeRails = function(steps) {
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


  TrackMesh.prototype.prepareSpine = function() {
    this.spineGeometry = new THREE.Geometry;
    if (this.spineShapeNeedsUpdate && this.spineShape) {
      this.spineShapeNeedsUpdate = false;
      this._spineVertices = this.spineShape.extractPoints(1).shape;
      this._spineFaces = THREE.Shape.Utils.triangulateShape(this._spineVertices, []);
    }
  };

  TrackMesh.prototype.spineStep = function(pos, normal, binormal) {
    if (!this.spineShape) {
      return;
    }
    return this._extrudeVertices(this._spineVertices, this.spineGeometry.vertices, pos, normal, binormal);
  };

  TrackMesh.prototype.finalizeSpine = function(spineSteps) {
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


  TrackMesh.prototype.prepareTies = function() {
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

  TrackMesh.prototype.tieStep = function(pos, normal, binormal, useExtended) {
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

  TrackMesh.prototype.finalizeTies = function(tieSteps) {
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
  function TrackModel(points) {
    this.points = points;
    this.rebuild();
  }

  TrackModel.prototype.rebuild = function() {
    var i, knot, knots, p, _i, _len, _ref;
    knots = [0, 0, 0, 0];
    _ref = this.points;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      p = _ref[i];
      knot = (i + 1) / (this.points.length - 3);
      knots.push(THREE.Math.clamp(knot, 0, 1));
    }
    return this.spline = new THREE.NURBSCurve(3, knots, this.points);
  };

  TrackModel.prototype.isConnected = false;

  TrackModel.prototype.getBankAt = function(t) {
    return 0;
  };

  return TrackModel;

})();
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.Train = (function(_super) {
  var down, mat, up, zero;

  __extends(Train, _super);

  function Train(track, options) {
    var geo, loader, mat,
      _this = this;
    this.track = track;
    if (options == null) {
      options = {};
    }
    Train.__super__.constructor.call(this);
    this.numberOfCars = options.numberOfCars, this.velocity = options.velocity;
    this.cars = [];
    if (this.numberOfCars == null) {
      this.numberOfCars = 1;
    }
    this.velocity = 20;
    this.displacement = 0;
    if (track != null ? track.carModel : void 0) {
      loader = new THREE.ColladaLoader;
      loader.load("resources/models/" + track.carModel, function(result) {
        var child, _i, _len, _ref;
        _this.carProto = result.scene.children[0];
        _this.carProto.scale.copy(track.carScale);
        _this.carRot = new THREE.Matrix4().makeRotationFromEuler(track.carRotation, 'XYZ');
        _ref = _this.carProto.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          child.castShadow = true;
        }
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
    var car, i, _i, _ref;
    while (this.cars.length) {
      this.remove(this.cars.pop());
    }
    if (this.numberOfCars) {
      for (i = _i = 1, _ref = this.numberOfCars; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        car = this.carProto.clone();
        if (i === this.numberOfCars) {
          car.remove(car.getObjectByName('connector'));
        }
        this.cars.push(car);
        this.add(car);
      }
    }
    return this.currentTime = 0.0;
  };

  up = new THREE.Vector3(0, 1, 0);

  down = new THREE.Vector3(0, -1, 0);

  zero = new THREE.Vector3();

  mat = new THREE.Matrix4();

  Train.prototype.simulate = function(delta) {
    var a, alpha, bank, binormal, car, deltaPoint, desiredDistance, i, lastPos, model, normal, pos, tangent, _i, _len, _ref;
    if (!this.numberOfCars || !(model = this.track.model)) {
      return;
    }
    if (this.lastTangent) {
      alpha = down.angleTo(this.lastTangent);
      a = 9.81 * Math.cos(alpha);
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
        car.position.copy(pos).add(zero.applyMatrix4(mat));
        car.rotation.setFromRotationMatrix(mat.multiply(this.carRot));
        if (LW.onRideCamera) {
          LW.renderer.camera.position.copy(pos).add(new THREE.Vector3(0, 3, 0).applyMatrix4(mat));
          LW.renderer.camera.rotation.setFromRotationMatrix(mat);
        }
      }
    }
  };

  return Train;

})(THREE.Object3D);
var CONTROL_COLOR, NODE_GEO, POINT_COLOR, SELECTED_COLOR,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CONTROL_COLOR = 0x0000ee;

POINT_COLOR = 0xdddddd;

SELECTED_COLOR = 0xffffff;

NODE_GEO = new THREE.SphereGeometry(1);

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
      if (!this.rerenderTimeout) {
        this.rerenderTimeout = setTimeout(function() {
          _this.rerenderTimeout = null;
          _this.model.rebuild();
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
      return this.transformControl.attach(node);
    }
  };

  EditTrack.prototype.rebuild = function() {
    var i, node, point, _i, _len, _ref;
    this.clear();
    this.controlPoints = [];
    if (this.model !== LW.model) {
      this.model = LW.model;
    }
    if (!this.model) {
      return;
    }
    _ref = this.model.points;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      point = _ref[i];
      node = new THREE.Mesh(NODE_GEO, new THREE.MeshLambertMaterial({
        color: CONTROL_COLOR
      }));
      node.position.copy(point);
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
    if (LW.onRideCamera) {
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
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LW.BMInvertedTrack = (function(_super) {
  var boxShape, boxSize, offsetX, offsetY, padding, radius, tieShape;

  __extends(BMInvertedTrack, _super);

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

  offsetY = 0;

  padding = boxSize / 4;

  tieShape = new THREE.Shape;

  tieShape.moveTo(-boxSize, -boxSize + 3 + padding);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY - radius * 0.75);

  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY - radius * 0.75);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY);

  tieShape.lineTo(boxSize, -boxSize + 3 + padding);

  BMInvertedTrack.prototype.tieShape = tieShape;

  tieShape = new THREE.Shape;

  tieShape.moveTo(-boxSize - padding, -boxSize + 3 + padding);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY);

  tieShape.lineTo(-offsetX + radius * 1.5, offsetY - radius * 0.75);

  tieShape.lineTo(-boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(boxSize / 2, -boxSize + 2.5);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY - radius * 0.75);

  tieShape.lineTo(offsetX - radius * 1.5, offsetY);

  tieShape.lineTo(boxSize + padding, -boxSize + 3 + padding);

  tieShape.lineTo(boxSize + padding, boxSize + 3 + padding);

  tieShape.lineTo(-boxSize - padding, boxSize + 3 + padding);

  BMInvertedTrack.prototype.extendedTieShape = tieShape;

  BMInvertedTrack.prototype.tieDepth = 0.4;

  BMInvertedTrack.prototype.railRadius = radius;

  BMInvertedTrack.prototype.railDistance = offsetX - radius;

  BMInvertedTrack.prototype.carModel = 'inverted.dae';

  BMInvertedTrack.prototype.carScale = new THREE.Vector3(0.0429, 0.0429, 0.037);

  BMInvertedTrack.prototype.carRotation = new THREE.Euler(-Math.PI * 0.5, 0, Math.PI, 'XYZ');

  BMInvertedTrack.prototype.carDistance = 9;

  function BMInvertedTrack() {
    BMInvertedTrack.__super__.constructor.apply(this, arguments);
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

  return BMInvertedTrack;

})(LW.TrackMesh);
