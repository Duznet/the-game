class Psg.Message extends Backbone.Model

  initialize: ->

class Psg.Messages extends Backbone.Collection

  model: Psg.Message

class Psg.Chat extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl
    @messages = new Psg.Messages
    @lastTime = @getCurrentTimestamp()
    @fetch()

  getCurrentTimestamp: ->
    d = new Date()
    (d.getTime() + d.getTimezoneOffset() * 60 * 1000) / 1000

  fetch: ->
    @conn.getMessages(@get('sid'), @get('game'), @lastTime).then (data) =>
      if data.result is 'ok'
        console.log 'data.messages: ', data.messages
        newMessages = if @messages.length > 0 then data.messages.splice(0, 1) else data.messages
        @messages.add newMessages
        if newMessages.length > 0
          @trigger 'newMessages', newMessages

  sendMessage: (text) ->
    @conn.sendMessage(@get('sid'), @get('game'), text)
