class LW.GUIController
  constructor: ->
    @modelProxy = new LW.TrackModel(null, null, true)

    @vertexProxy = new THREE.Vector4(50, 50, 50, 0.5)
    @rollProxy = new LW.RollNode(position: 0.05, amount: 100)
    @segmentProxy = new LW.Separator()

    @gui = new dat.GUI()

    if LW.edit
      @addSaveBar()
      @gui.add(LW.edit, 'mode', (val for own key, val of LW.EditController.MODES)).name("tool")

      @vertexFolder = @gui.addFolder("Vertex Properties")
      @vertexFolder.add(@vertexProxy, 'x', -100, 100).onChange(@changeVertex)
      @vertexFolder.add(@vertexProxy, 'y', 0, 200).onChange(@changeVertex)
      @vertexFolder.add(@vertexProxy, 'z', -100, 100).onChange(@changeVertex)
      @vertexFolder.add(@vertexProxy, 'w', 0, 3.5).name("weight").onChange(@changeVertex)
      @vertexFolder.__ul.classList.add('hidden')

      LW.edit.observe('nodeMoved', @nodeMoved)
      LW.edit.observe('selectionChanged', @selectionChanged)

      @rollFolder = @gui.addFolder("Roll Properties")
      @rollFolder.add(@rollProxy, 'position', 0.01, 0.99).name("position").onChange(@changeRoll)
      @rollFolder.add(@rollProxy, 'amount', -360, 360).name("amount").onChange(@changeRoll)
      @rollFolder.__ul.classList.add('hidden')

      @styleFolder = @gui.addFolder("Style Properties")
      @styleFolder.addColor(@segmentProxy, 'spineColor').name("spine color").onChange(@changeColor('spine'))
      @styleFolder.addColor(@segmentProxy, 'tieColor').name("tie color").onChange(@changeColor('tie'))
      @styleFolder.addColor(@segmentProxy, 'railColor').name("rail color").onChange(@changeColor('rail'))
      @styleFolder.addColor(@segmentProxy, 'wireframeColor').name("wireframe color").onChange(@changeColor('wireframe'))

    @viewFolder = @gui.addFolder("View Properties")
    @viewFolder.add(LW.renderer, 'showFPS').name("show FPS").onChange(@changeShowFPS)
    @viewFolder.add(LW.renderer, 'useQuadView').name("quad view")
    @viewFolder.add(@modelProxy, 'forceWireframe').name("force wireframe").onChange(@changeForceWireframe)
    @viewFolder.add(@modelProxy, 'debugNormals').name("show normals").onChange(@changeDebugNormals)
    @viewFolder.add(LW.train.cameraHelper, 'visible').name("debug ride cam") if LW.train

    @gui.add(@modelProxy, 'onRideCamera').name("ride it!").onChange(@changeOnRideCamera)

  updateFolder: (folder) ->
    return if not folder
    controller.updateDisplay() for controller in folder.__controllers

  modelChanged: (track) ->
    @modelProxy.fromJSON(track.toJSON())
    @segmentProxy.fromJSON(track.toJSON())
    @updateFolder(@viewFolder, false)

  nodeMoved: (mesh) =>
    return if @ignoreNodeMoved

    if mesh.isVertex
      @vertexProxy.copy(mesh.node)
      @updateFolder(@vertexFolder)
    else
      @rollProxy.copy(mesh.node)
      @updateFolder(@rollFolder)

  selectionChanged: (@selected, selection) =>
    if selection.length == 1
      if selected.isVertex
        @vertexFolder.open()
        @rollFolder.close()
      else if selected.isRollNode || selected.isSeparator
        @rollFolder.open()
        @vertexFolder.close()
        @styleFolder.open() if selected.isSeparator

      if selected.node
        @nodeMoved(selected)
    else
      @vertexFolder.close()
      @rollFolder.close()

  changeVertex: =>
    @selected.node.copy(@vertexProxy)
    @selected.transformControl.update()

    @ignoreNodeMoved = true
    LW.edit.nodeMoved(@selected)
    @ignoreNodeMoved = false

  changeRoll: =>
    @selected.node.copy(@rollProxy)

    @ignoreNodeMoved = true
    LW.edit.nodeMoved(@selected)
    @ignoreNodeMoved = false

  changeColor: (key) ->
    return (value) ->
      selected = LW.edit.selected
      if selected instanceof LW.Separator
        selected["#{key}Color"] = value
        selected.meshColor.setStyle(value)
        line.geometry.colorsNeedUpdate = true for line in LW.track.meshes
      else
        LW.model["#{key}Color"] = value
        LW.track?.updateMaterials()

  changeShowFPS: (value) ->
    node = LW.renderer.stats.domElement
    if value
      LW.renderer.domElement.parentNode.appendChild(node)
    else
      node.parentNode.removeChild(node)

  changeOnRideCamera: (value) ->
    LW.getTrain().start() if value
    LW.model.onRideCamera = value

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

    vertices = [
      new THREE.Vector4(-100, 20, 0, 1)
      new THREE.Vector4(-20, 20, 0, 1)
      new THREE.Vector4(20, 30, 0, 1)
      new THREE.Vector4(60, 20, 0, 1)
      new THREE.Vector4(100, 0, 0, 1)
      new THREE.Vector4(200, 0, 0, 1)
      new THREE.Vector4(250, 60, 0, 1)
    ]

    track = new LW.TrackModel(vertices, LW.NurbsSpline)
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

    LW.setModel(track)

  loadTracks: (autoload) ->
    @dropdown.innerHTML = ''

    try
      tracks = JSON.parse(localStorage.getItem('tracks'))
      if tracks?.length
        for track in tracks
          @_addTrackToDropdown(track)
        @loadTrack(track) if autoload
      else
        @newTrack() if autoload

    catch e
      console.log e
      console.log e.stack

      if confirm("Well, seems like I've gone and changed the track format again. Press OK to erase all your tracks and start over or Cancel to try reloading. Sorry mate!")
        localStorage.clear()
        @loadTracks()
      else
        window.location.reload()

  clearAllTracks: ->
    if confirm("This will remove all your tracks. Are you sure you wish to do this?")
      localStorage.clear()
      @loadTracks(true)

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
    return if not @dropdown

    option = document.createElement('option')
    option.innerHTML = name
    option.value = name
    option.selected = true
    @dropdown.appendChild(option)

oldUpdateDisplay = dat.controllers.BooleanController::updateDisplay
dat.controllers.BooleanController::updateDisplay = ->
  @__prev = @getValue()
  return oldUpdateDisplay.call(this)
