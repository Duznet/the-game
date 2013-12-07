class Psg.Router extends Backbone.Router

  routes:
    '': 'home'
    'welcome': 'welcome'

  initialize: ->
    @app = new Psg.Application

  home: ->
    if @app.user is null
      @navigate 'welcome', trigger: true
    else
      console.log 'home!'

  welcome: ->
    console.log 'welcome'
    wv = new Psg.AuthView model: new Psg.Auth
    $('#nav-signin').click()
