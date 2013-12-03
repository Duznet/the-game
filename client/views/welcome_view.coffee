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
    'click #submit-btn': 'submit'

  switchFormState: (state, event) ->
    if event then event.preventDefault()
    stateData =
      signin:
        btnName: 'Sign in'
        opposite: 'signup'
      signup:
        btnName: 'Sign up'
        opposite: 'signin'

    @formState = state
    console.log "formState: ", @formState
    formData = @dataInputTemplate()
    formData += if @formState is 'signup' then @repeatPasswordInputTemplate() else ''
    formData += @submitBtnTemplate(btnName: stateData[state].btnName)
    @$el.html @template formData: formData
    $("#nav-#{state}").addClass 'active'
    $("#nav-#{stateData[state].opposite}").removeClass 'active'

  navSignin: (e) ->
    @switchFormState 'signin', e

  navSignup: (e) ->
    @switchFormState 'signup', e

  submit: (e) ->
    if e then e.preventDefault()
    console.log 'submit'


  initialize: ->
    @render()

  render: ->
    @$el.appendTo $('body')
    @$el.html @template(formData: "")
    return this
