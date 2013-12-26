class Psg.GameConnection extends Psg.Connection

  send: (requestData) ->
    $.ajax
      type: 'POST'
      url: @url
      dataType: 'json'
      contentType: 'application/json'
      data: requestData

  __requestWithSid__: (action, params) ->
    params = params || {}
    params.sid = @sid
    req = @request action, params
    req.then (data) =>
      dfd = new $.Deferred
      if data.result is 'badSid'
        @trigger 'sessionLost'
        dfd.resolve data
      if data.result is 'badRequest' or data.result is 'badAction' or data.result is 'badJSON'
        console.log 'action: ', action
        console.log 'params: ', params
        throw new Error "got #{data.result}"
    req

  startTesting: (params) ->
    @request 'startTesting', params

  signup: (params) ->
    @request 'signup', params

  signin: (params) ->
    @request 'signin', params

  signout: (params) ->
    @__requestWithSid__ 'signout', params

  sendMessage: (params) ->
    @__requestWithSid__ 'sendMessage', params

  getMessages: (params) ->
    @__requestWithSid__ 'getMessages', params

  uploadMap: (params) ->
    @__requestWithSid__ 'uploadMap', params

  getMaps: (params) ->
    @__requestWithSid__ 'getMaps', params

  createGame: (params) ->
    @__requestWithSid__ 'createGame', params

  getGames: (params) ->
    @__requestWithSid__ 'getGames', params

  joinGame: (params) ->
    @__requestWithSid__ 'joinGame', params

  leaveGame: (params) ->
    @__requestWithSid__ 'leaveGame', params
