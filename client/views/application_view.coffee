class Psg.ApplicationView extends Backbone.View

  tagName: 'div'
  id: 'application'

  template: _.template $('#application-template').html()

  initialize: ->
    @render()

  render: ->
    @$el.html @template
      login: @model.user.get 'login'
    $body = $('body')
    $body.empty()
    $body.append @$el
