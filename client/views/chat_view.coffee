class Psg.MessageView extends Backbone.View

  template: _.template $('#message-template').html()

  initialize: ->
    @render()

  render: ->
    zerofill = (number) ->
      ('0' + number).slice(-2)
    t = new Date()
    date = new Date(@model.get('time') * 1000 - t.getTimezoneOffset() * 60 * 1000)
    time = "#{zerofill(date.getHours())}:#{zerofill(date.getMinutes())}:#{zerofill(date.getSeconds())}"
    @$el.append @template(login: @model.get('login'), text: @model.get('text'), time: time)

class Psg.ChatView extends Backbone.View

  tagName: 'div'
  className: 'chat'
  template: _.template $('#chat-template').html()

  events:
    'click .submit-btn': 'submit'

  initialize: ->
    @render()
    @lastMessageIndex = 0
    @model.on 'newMessages', @onNewMessages

  onNewMessages: =>
    $parent = @$el.find('.chat-log')
    messages = @model.messages.rest @lastMessageIndex
    @lastMessageIndex = @model.messages.length
    for m in messages
      new Psg.MessageView model: m, el: $parent
      $parent.scrollTop $parent[0].scrollHeight

  submit: (e) ->
    e.preventDefault()
    @model.sendMessage @$el.find('.message-input').val()
    @$el.find('.message-input').val('')

  render: ->
    @$el.html @template()
    $sidebar = $('#sidebar')
    $sidebar.empty()
    $sidebar.append @$el
    @lastMessageIndex = 0
    @onNewMessages()
