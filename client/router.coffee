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
    console.log wv
    console.log wv.$el
    $app = $('#application')
    $app.empty()
    $app.append wv.$el
