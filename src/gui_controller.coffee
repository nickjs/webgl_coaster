class LW.GUIController
  constructor: ->
    @gui = new dat.GUI()

    @vertexProxy = new THREE.Vector4
    @vertexFolder = @gui.addFolder("Vertex Properties")
    @vertexFolder.add(@vertexProxy, 'x', -250, 250).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'y', 0, 500).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'z', -250, 250).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'w', 0, Math.PI).name("weight").onChange(@changeVertex)

    LW.edit.observe('vertexChanged', @vertexChanged)

    @viewFolder = @gui.addFolder("View Properties")
    @viewFolder.add(LW.renderer, 'showFPS').name("show FPS").onChange (value) ->
      node = LW.renderer.stats.domElement
      if value
        LW.renderer.domElement.parentNode.appendChild(node)
      else
        node.parentNode.removeChild(node)

    @viewFolder.add(LW.renderer, 'onRideCamera').name("ride camera").onChange(@changeOnRideCamera)
    @viewFolder.add(LW.renderer, 'useQuadView').name("quad view")
    @viewFolder.add(LW.track, 'forceWireframe').name("force wireframe").onChange (value) ->
      if value
        LW.track?.wireframe = true
      else
        LW.track?.wireframe = !!LW.edit?.selected

      LW.track?.rebuild()

    @viewFolder.add(LW.track, 'debugNormals').name("show normals").onChange -> LW.track?.rebuild()

    @addSaveBar()
    @loadTracks()

  updateFolder: (folderKey, openFolder) ->
    controller.updateDisplay() for controller in @[folderKey].__controllers
    @[folderKey][if openFolder then 'open' else 'close']()

  vertexChanged: (vertex) =>
    if vertex
      @vertexProxy.copy(vertex.point)
    else
      @vertexProxy.set(0, 0, 0)

    @updateFolder('vertexFolder', !!vertex)

  changeVertex: =>
    LW.edit.transformControl.update()
    LW.edit.selected.position.copy(@vertexProxy)
    LW.edit.selected.point.copy(@vertexProxy)
    LW.edit.changed()

  changeOnRideCamera: (value) =>
    if value
      @oldCamPos = LW.renderer.camera.position.clone()
      @oldCamRot = LW.renderer.camera.rotation.clone()
      LW.renderer.scene.remove(LW.edit)
    else
      LW.renderer.camera.position.copy(@oldCamPos)
      LW.renderer.camera.rotation.copy(@oldCamRot)
      LW.renderer.scene.add(LW.edit)

  newTrack: ->
    @_addTrackToDropdown("Untitled")

    track = new LW.TrackModel([
      new THREE.Vector4(-100, 20, 0, 1)
      new THREE.Vector4(-20, 20, 0, 1)
      new THREE.Vector4(20, 30, 0, 1)
      new THREE.Vector4(60, 20, 0, 1)
      new THREE.Vector4(100, 0, 0, 1)
      new THREE.Vector4(200, 0, 0, 1)
      new THREE.Vector4(250, 60, 0, 1)
    ])

    @loadTrack(track)

  saveTrack: ->
    if not LW.model.name
      name = prompt("What do you want to call this track?")
      return if !name

      tracks = JSON.parse(localStorage.getItem('tracks')) || []
      if tracks.indexOf(name) != -1
        if !confirm("A track with name #{name} already exists. Are you sure you want to overwrite it?")
          return @saveTrack()

      LW.model.name = name

      tracks.push(name)
      localStorage.setItem('tracks', JSON.stringify(tracks))

      @_addTrackToDropdown(name)

    localStorage.setItem("track.#{LW.model.name}", JSON.stringify(LW.model.toJSON()))

  loadTrack: (track) ->
    if typeof track is 'string'
      json = JSON.parse(localStorage.getItem("track.#{track}"))

      track = new LW.TrackModel
      track.fromJSON(json)

    LW.model = track
    LW.edit?.rebuild()
    LW.track?.rebuild()
    LW.train?.start()

  loadTracks: ->
    @dropdown.innerHTML = ''

    try
      tracks = JSON.parse(localStorage.getItem('tracks'))
      if tracks?.length
        for track in tracks
          @_addTrackToDropdown(track)
        @loadTrack(track)
      else
        @newTrack()

    catch e
      console.log e
      console.log e.stack

      alert("Well, seems like I've gone and changed the track format again. Unfortunately I'll have to clear all your tracks now. Sorry mate!")
      localStorage.clear()

      @loadTracks()

  clearAllTracks: ->
    if confirm("This will remove all your tracks. Are you sure you wish to do this?")
      localStorage.clear()
      @loadTracks()

  addSaveBar: ->
    saveRow = document.createElement('li')
    saveRow.classList.add('save-row')
    saveRow.style.width = '245px'
    @gui.__ul.insertBefore(saveRow, @gui.__ul.firstChild)
    @gui.domElement.classList.add('has-save')

    @dropdown = document.createElement('select')
    @dropdown.addEventListener('change', => @loadTrack(@dropdown.value))
    saveRow.appendChild(@dropdown)

    newButton = document.createElement('span')
    newButton.innerHTML = 'New'
    newButton.className = 'button new'
    newButton.addEventListener('click', => @newTrack())
    saveRow.appendChild(newButton)

    saveButton = document.createElement('span')
    saveButton.innerHTML = 'Save'
    saveButton.className = 'button save'
    saveButton.addEventListener('click', => @saveTrack())
    saveRow.appendChild(saveButton)

    clearButton = document.createElement('span')
    clearButton.innerHTML = 'Reset'
    clearButton.className = 'button clear'
    clearButton.addEventListener('click', => @clearAllTracks())
    saveRow.appendChild(clearButton)

    gears = document.createElement('span')
    gears.innerHTML = '&nbsp;'
    gears.className = 'button gears'
    saveRow.appendChild(gears)

  _addTrackToDropdown: (name) ->
    option = document.createElement('option')
    option.innerHTML = name
    option.value = name
    option.selected = true
    @dropdown.appendChild(option)

###
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
###
