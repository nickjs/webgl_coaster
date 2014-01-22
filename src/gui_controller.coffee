class LW.GUIController
  constructor: ->
    @gui = new dat.GUI()

    @modelProxy = new LW.TrackModel

    @vertexProxy = new THREE.Vector4
    @vertexFolder = @gui.addFolder("Vertex Properties")
    @vertexFolder.add(@vertexProxy, 'x', -250, 250).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'y', 0, 500).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'z', -250, 250).onChange(@changeVertex)
    @vertexFolder.add(@vertexProxy, 'w', 0, Math.PI).name("weight").onChange(@changeVertex)

    LW.edit.observe('vertexChanged', @vertexChanged)

    @viewFolder = @gui.addFolder("View Properties")
    @viewFolder.add(LW.renderer, 'showFPS').name("show FPS").onChange(@changeShowFPS)
    @viewFolder.add(LW.renderer, 'useQuadView').name("quad view")
    @viewFolder.add(@modelProxy, 'onRideCamera').name("ride camera").onChange(@changeOnRideCamera)
    @viewFolder.add(@modelProxy, 'forceWireframe').name("force wireframe").onChange(@changeForceWireframe)
    @viewFolder.add(@modelProxy, 'debugNormals').name("show normals").onChange(@changeDebugNormals)

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

  changeShowFPS: (value) ->
    node = LW.renderer.stats.domElement
    if value
      LW.renderer.domElement.parentNode.appendChild(node)
    else
      node.parentNode.removeChild(node)

  changeOnRideCamera: (value) =>
    LW.model.onRideCamera = value

    if value
      @oldCamPos = LW.renderer.camera.position.clone()
      @oldCamRot = LW.renderer.camera.rotation.clone()
      LW.renderer.scene.remove(LW.edit)
    else
      @oldCamPos ||= LW.renderer.defaultCamPos
      @oldCamRot ||= LW.renderer.defaultCamRot

      LW.renderer.camera.position.copy(@oldCamPos)
      LW.renderer.camera.rotation.copy(@oldCamRot)
      LW.renderer.scene.add(LW.edit)

  changeForceWireframe: (value) ->
    LW.model.forceWireframe = value

    if value
      LW.track?.wireframe = true
    else
      LW.track?.wireframe = !!LW.edit?.selected

    LW.track?.rebuild()

  changeDebugNormals: (value) ->
    LW.model.debugNormals = value
    LW.track?.rebuild()

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

    @modelProxy.fromJSON(track.toJSON())
    @updateFolder('viewFolder', false)

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

dat.controllers.BooleanController::updateDisplay = ->
  @__prev = @getValue()

  if @__prev == true
    @__checkbox.setAttribute('checked', 'checked')
    @__checkbox.checked = true
  else
    @__checkbox.checked = false

  return dat.controllers.BooleanController.superclass::updateDisplay.call(this)
