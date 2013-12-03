class Psg.WelcomeView extends Backbone.View

  tagName: 'div'
  className: 'container'
  id: 'welcome'

  template: _.template $('#welcome-template').html()
  dataInputTemplate: _.template $('#welcome-data-input').html()
  repeatPasswordInputTemplate: _.template $('#welcome-repeat-password-input').html()
  submitBtnTemplate: _.template $('#welcome-submit-btn').html()

  events:
    'click #nav-signin': 'navSignin'
    'click #nav-signup': 'navSignup'

  navSignin: (e) ->
    if e then e.preventDefault()
    console.log 'navSignin'
    @$el.html @template formData: "#{@dataInputTemplate()}\n#{@submitBtnTemplate()}"
    $('#nav-signup').removeClass 'active'
    $('#nav-signin').addClass 'active'
    $('#submit-btn').html 'Sign in'

  navSignup: (e) ->
    if e then e.preventDefault()
    console.log 'navSignup'
    @$el.html @template formData: "#{@dataInputTemplate()}\n#{@repeatPasswordInputTemplate()}\n#{@submitBtnTemplate()}"
    $('#nav-signin').removeClass 'active'
    $('#nav-signup').addClass 'active'
    $('#submit-btn').html 'Sign up'


  initialize: ->
    @render()

  render: ->
    @$el.appendTo $('body')
    @$el.html @template(formData: "")
    return this
