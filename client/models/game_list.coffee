class Psg.GameListItem extends Backbone.Model

  initialize: ->

class Psg.Games extends Backbone.Collection

  model: Psg.GameListItem

class Psg.GameList extends Backbone.Model

  initialize: ->
    @conn = @get('user').conn
    @games = new Psg.Games

  startRefreshing: ->
    @refreshInterval = setInterval =>
      @fetch()
    , config.chatRefreshInterval

  stopRefreshing: ->
    clearInterval @refreshInterval

  fetch: ->
    @conn.getMaps().then (mapsData) =>
      if mapsData.result is 'ok'
        maps = mapsData.maps
        @conn.getGames().then (data) =>
          if data.result is 'ok'
            games = data.games.filter (g) -> g.status is 'running'
            games = games.map (g) ->
              mapName = _.findWhere(maps, id: g.map).name
              g.map = mapName
              g
            @games.set games
            @trigger 'refreshed'
