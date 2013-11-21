class window.GameError
  constructor: (@message) ->

class window.Connection
  constructor: (@url) ->

  request: (action, params) ->
    response = @send JSON.stringify action: action, params: params
