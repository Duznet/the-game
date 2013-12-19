class Psg.GameCreatorView extends Backbone.View

  template: _.template $('#game-creator-template').html()

  tagName: 'div'

  events:
    'click #submit-btn': 'submit'

  initialize: ->
    @render()
    @listenTo @model, 'submitFailed', @onSubmitFailed
    @listenTo @model, 'invalid', @onInvalid
    @listenTo @model, 'mapListUpdated', @onMapListUpdated

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

  onMapListUpdated: ->
    console.log 'on map list updated'
    $selectMap = $('#select-map')
    $selectMap.val null
    mapList = @getMapList()
    for m in mapList
      $selectMap.append m

  getMapList: ->
    @model.maps.map (m) -> "<option value=\"#{m.id}\">#{m.name} (#{m.maxPlayers})</option>"

  render: ->
    @model.getMaps().then
    $content = $('#content')
    # mapList = @getMapList()
    @$el.html @template(maps: '')
    @$el.appendTo $content

  writeStatus: (status, text) ->
    $container = $('#map-upload-status-container')
    if status is 'success'
      $container.removeClass 'has-error'
      $container.addClass 'has-success'
    else
      $container.removeClass 'has-success'
      $container.addClass 'has-error'
    $('#game-create-status').html text

  submit: (e) ->
    e.preventDefault()
    data = {}
    data.name = $('#input-name').val()
    data.maxPlayers = $('#input-max-players').val()
    data.map = $('#select-map').val()
    console.log 'data: ', data
    @model.set data, validate: true
    @model.create()

