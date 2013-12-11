class LW.GUIController
  constructor: ->
    @gui = new dat.GUI()
    @gui.addColor(color: '#ffffff', 'color')

    @addSaveBar()
    @loadTracks()

  newTrack: ->
    @_addTrackToDropdown("Untitled")

    LW.spline = new LW.BezierPath([
      new LW.Point(-20,0,0, -10,0,0, 10,0,0)
      new LW.Point(20,0,0, -10,0,0, 10,0,0)
    ])

    LW.edit?.rebuild()
    LW.track?.rebuild()

  loadTracks: ->
    @dropdown.innerHTML = ''

    tracks = localStorage.getItem('tracks')
    if tracks?.length
      for track in JSON.parse(tracks)
        @_addTrackToDropdown(track)
    else
      @newTrack()

  addSaveBar: ->
    saveRow = document.createElement('li')
    saveRow.classList.add('save-row')
    saveRow.style.width = '245px'
    @gui.__ul.insertBefore(saveRow, @gui.__ul.firstChild)
    @gui.domElement.classList.add('has-save')

    @dropdown = document.createElement('select')
    saveRow.appendChild(@dropdown)

    newButton = document.createElement('span')
    newButton.innerHTML = 'New'
    newButton.className = 'button new'
    newButton.addEventListener('click', => @newTrack())
    saveRow.appendChild(newButton)

    saveButton = document.createElement('span')
    saveButton.innerHTML = 'Save'
    saveButton.className = 'button save'
    saveRow.appendChild(saveButton)

    gears = document.createElement('span')
    gears.innerHTML = '&nbsp;'
    gears.className = 'button gears'
    saveRow.appendChild(gears)

  _addTrackToDropdown: (name) ->
    option = document.createElement('option')
    option.innerHTML = name
    option.value = name
    @dropdown.appendChild(option)
