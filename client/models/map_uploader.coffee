class Psg.MapUploader extends Backbone.Model

  initialize: ->
    @conn = @get('user').conn

  validate: (attrs) ->
    console.log 'validating: ', attrs
    errors = []
    if attrs.name.length is 0 then errors.push 'Name must not be empty'
    if isNaN attrs.maxPlayers
      errors.push 'Max players must be a number'
    else
      if attrs.maxPlayers < 1 then errors.push 'Map must allow to play at least one player'
    if attrs.mapData
      if attrs.mapData.length is 0 or attrs.mapData[0].length is 0
        errors.push 'Map must not be empty'
      else
        rowLength = attrs.mapData[0].length
        for r in attrs.mapData
          if r.length isnt rowLength
            errors.push 'Row lengths in map data must be equal'
            break
    if errors.length > 0 then errors

  upload: ->
    @conn.uploadMap(
      name: @get('name')
      maxPlayers: parseInt @get('maxPlayers')
      map: @get('mapData')
    ).then (data) =>
      if data.result is 'ok'
        @trigger 'uploaded'
      else
        @trigger 'submitFailed', data.result
