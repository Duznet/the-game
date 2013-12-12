class Psg.Message extends Backbone.Model

  initialize: ->

class Psg.Messages extends Backbone.Collection

  model: Psg.Message

class Psg.Chat extends Backbone.Model

  initialize: ->
    @conn = @get('user').conn
    @messages = new Psg.Messages
    @lastTime = @getCurrentTimestamp()


  startRefreshing: ->
    @refreshInterval = setInterval =>
      @fetch()
    , config.chatRefreshInterval

  stopRefreshing: ->
    clearInterval @refreshInterval

  getCurrentTimestamp: ->
    d = new Date()
    (d.getTime() + d.getTimezoneOffset() * 60 * 1000) / 1000

  fetch: ->
    @conn.getMessages(game: @get('game'), since: @lastTime).then (data) =>
      if data.result is 'ok'
        newMessages = if @messages.models.length > 0 then _.rest data.messages else data.messages
        if newMessages.length > 0
          @messages.add newMessages
        if newMessages.length > 0
          @lastTime = newMessages[newMessages.length - 1].time
          @trigger 'newMessages', newMessages

  sendMessage: (text) ->
    @conn.sendMessage(game: @get('game'), text: text)
