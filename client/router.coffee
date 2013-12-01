class Psg.Router extends Backbone.Router

  routes:
    '': 'home'
    'welcome': 'welcome'

  initialize: ->
    @app = new Psg.Application

  home: ->
    if @app.user is null
      window.location.hash = 'welcome'
    else
      console.log 'home!'

  welcome: ->
    console.log 'welcome'
    wv = new Psg.WelcomeView
    $body = $('body')
    $body.empty()
    $body.append wv.$el
    console.log wv.el
