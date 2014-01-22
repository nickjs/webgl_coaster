LW.Observable = {
  observe: (key, callback) ->
    @_observers ||= {}
    @_observers[key] ||= []
    @_observers[key].push(callback)

  fire: (key, value, oldValue) ->
    callbacks = @_observers?[key]
    if callbacks?.length
      for callback in callbacks
        callback(value, oldValue)
}
