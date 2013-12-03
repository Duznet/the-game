class Psg.WelcomeView extends Backbone.View

  tagName: 'div'
  className: 'container'
  id: 'welcome'

  template: _.template $('#welcome-template').html()

  events:
    'click #nav-signin': 'navSignin'
    'click #nav-signup': 'navSignup'

  navSignin: ->
    alert 'clicked signin'

  navSignup: ->
    alert 'clicked signup'

  initialize: ->
    @render()

  render: ->
    value =
      head: 'Welcome to the platform shooter game'
      text: 'Hello, this is some text'
    @$el.html @template value
