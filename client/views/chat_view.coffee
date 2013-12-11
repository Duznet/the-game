class Psg.MessageView extends Backbone.View

  template: _.template $('#message-template').html()

  initialize: ->
    @render()

  render: ->
    t = new Date()
    date = new Date(@model.get('time') * 1000 - t.getTimezoneOffset() * 60 * 1000)
    time = "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
    @$el.append @template(login: @model.get('login'), text: @model.get('text'), time: time)

class Psg.ChatView extends Backbone.View

  tagName: 'div'
  className: 'chat'
  template: _.template $('#chat-template').html()

  events:
    'click .submit-btn': 'submit'

  initialize: ->
    @render()
    console.log @$el
    @model.on 'newMessages', @onNewMessages

  onNewMessages: (messages) =>
    $parent = @$el.find('.chat-log')
    for m in messages
      model = new Psg.Message m
      new Psg.MessageView model: model, el: $parent
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
