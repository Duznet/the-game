class Psg.WelcomeView extends Backbone.View

  tagName: 'div'
  className: 'container'
  id: 'welcome'

  template: _.template $('#welcome-template').html()

  initialize: ->
    @render()

  render: ->
    value =
      head: 'Welcome to the platform shooter game'
      text: 'Hello, this is some text'
    @$el.html @template value
