class Psg.Connection
  constructor: (@url) ->

  request: (action, params) ->
    if config.debug.showRequests
      console.log 'request: ', action, params
    response = @send JSON.stringify action: action, params: params
