class Psg.MapUploaderView extends Backbone.View

  template: _.template $('#map-uploader-template').html()

  tagName: 'div'

  events:
    'click #submit-btn': 'submit'

  initialize: ->
    @render()
    @listenTo @model, 'submitFailed', @onSubmitFailed
    @listenTo @model, 'invalid', @onInvalid
    @listenTo @model, 'uploaded', @onUploaded

  onSubmitFailed: (result) ->
    switch result
      when 'badMap'
        @writeStatus 'error', 'Invalid map data'
      when 'badName'
        @writeStatus 'error', 'Invalid map name'
      when 'badMaxPlayers'
        @writeStatus 'error', 'Invalid map players number'
      when 'mapExists'
        @writeStatus 'error', 'Map with this name already exists'

  onInvalid: (model, errors) ->
    console.log errors
    @writeStatus 'error', errors.join('<br>')

  onUploaded: ->
    @writeStatus 'success', 'Map successfully uploaded'
    $('#input-name').empty()
    $('#input-max-players').empty()
    $('#input-map-data').empty()

  render: ->
    $content = $('#content')
    @$el.html @template()
    @$el.appendTo $content

  writeStatus: (status, text) ->
    $container = $('#map-upload-status')
    if status is 'success'
      $container.removeClass 'alert-danger'
      $container.addClass 'alert-success'
    else
      $container.removeClass 'alert-success'
      $container.addClass 'alert-danger'
    $container.html text

  submit: (e) ->
    e.preventDefault()
    data = {}
    data.name = $('#input-name').val()
    data.maxPlayers = $('#input-max-players').val()
    data.mapData = $('#input-map-data').val().split('\n')
    console.log 'data: ', data
    @model.set data, validate: true
    @model.upload()

