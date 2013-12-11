class Psg.Message extends Backbone.Model

  initialize: ->

class Psg.Messages extends Backbone.Collection

  model: Psg.Message

class Psg.Chat extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl
    @messages = new Psg.Messages
    @lastTime = @getCurrentTimestamp()
    setInterval =>
      @fetch()
    , config.chatRefreshInterval

  getCurrentTimestamp: ->
    d = new Date()
    (d.getTime() + d.getTimezoneOffset() * 60 * 1000) / 1000

  fetch: ->
    @conn.getMessages(@get('sid'), @get('game'), @lastTime).then (data) =>
      if data.result is 'ok'
        newMessages = if @messages.models.length > 0 then _.rest data.messages else data.messages
        if newMessages.length > 0
          @messages.add newMessages
        if newMessages.length > 0
          @lastTime = newMessages[newMessages.length - 1].time
          @trigger 'newMessages', newMessages

  sendMessage: (text) ->
    @conn.sendMessage(@get('sid'), @get('game'), text)
