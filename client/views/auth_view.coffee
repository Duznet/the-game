class Psg.AuthView extends Backbone.View

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

  initialize: ->
    @render()
    @model.on 'submitFailed', @onSumbitFailed
    @model.on 'authenticated', @onAuthenticated

  onSumbitFailed: (result) =>
    console.log 'submit failed'
    switch result
      when 'badLogin'
        @writeStatus 'login', 'error', 'incorrect login'
      when 'userExists'
        @writeStatus 'login', 'error', 'user exists'
      when 'badPassword'
        @writeStatus 'password', 'error', 'incorrect password'
      when 'incorrect'
        @writeStatus 'login', 'error', 'Incorrect login/password'
      else console.log result

  onAuthenticated: =>
    Backbone.history.navigate 'dashboard', trigger: true

  checkInputs: ->
    @inputIsValid = true

    @checkInput 'login'
    @checkInput 'password'
    if @formState is 'signup'
      @checkPasswordMatch()

  writeStatus: (input, status, message = '') ->
    inputGroup = $("##{input}-group")
    inputError = $("##{input}-error")
    if status is 'success'
      inputGroup.removeClass 'has-error'
    else if not inputGroup.hasClass 'has-error'
      inputGroup.addClass 'has-error'
    inputError.html message


  checkInput: (inputName) ->
    input = $("#input-#{inputName}")
    if 3 < input.val().length < 41
      @writeStatus "#{inputName}", 'success'
    else
      @inputIsValid = false
      if input.val().length < 4
        @writeStatus "#{inputName}", 'error', 'must be longer than 3 symbols'
      if input.val().length > 40
        @writeStatus "#{inputName}", 'error', 'must be shorter than 41 symbols'

  checkPasswordMatch: ->
    passwordInput = $('#input-password')
    repeatPasswordInput = $('#repeat-password')
    if passwordInput.val() is repeatPasswordInput.val()
      @writeStatus 'repeat-password', 'success'
    else
      @inputIsValid = false
      @writeStatus 'repeat-password', 'error', 'passwords must match'

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
    @checkInputs()
    if @inputIsValid
      login = $('#input-login').val()
      password = $('#input-password').val()
      @model[@formState] login, password


  render: ->
    @$el.appendTo $('body')
    @$el.html @template(formData: "")
    return this
