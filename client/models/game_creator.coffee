class Psg.GameCreator extends Backbone.Model

  initialize: ->
    @conn = @get('user').conn
    @maps = []

  getMaps: ->
    @conn.getMaps().then (data) =>
      if data.result is 'ok'
        @maps = data.maps
        console.log 'map list updated'
        @trigger 'mapListUpdated'

  validate: (attrs) ->
    console.log 'validating: ', attrs
    errors = []
    if attrs.name.length is 0 then errors.push 'Name must not be empty'
    if isNaN attrs.maxPlayers
      errors.push 'Max players must be a number'
    else if attrs.maxPlayers < 1 then errors.push 'Map must allow to play at least one player'
    else if attrs.maxPlayers > attrs.map.maxPlayers then errors.push 'Selected map doesn\'t allow to play with so many players'
    if errors.length > 0 then errors

  create: ->
    @conn.createGame(
      name: @get('name')
      maxPlayers: @get('maxPlayers')
      map: @get('map')
    ).then (data) =>
      if data.result is 'ok'
        @conn.getGames().then (data) =>
          login = @get('user').get('login')
          games = data.games.filter (g) ->
            players = g.players.filter (p) -> p is login
            players.length > 0
          id = games[0].id
          @trigger 'created', id
      else
        @trigger 'submitFailed', data.result
