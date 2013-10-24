class window.GameException
  constructor: (@type) ->

class window.Connector
  constructor: (@url) ->

  request: (action, params) ->
    response = @send JSON.stringify action: action, params: params
    if response.result isnt "ok"
      throw new GameException(response.result)


