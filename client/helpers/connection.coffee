class Psg.Connection extends Backbone.Events

  constructor: (attrs) ->
    @url = attrs.url
    @sid = attrs.sid || ''

  request: (action, params) ->
    response = @send JSON.stringify action: action, params: params

