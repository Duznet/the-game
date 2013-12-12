class Psg.Connection

  constructor: (attrs) ->
    _.extend @, Backbone.Events
    @url = attrs.url
    @sid = attrs.sid || ''

  request: (action, params) ->
    response = @send JSON.stringify action: action, params: params

