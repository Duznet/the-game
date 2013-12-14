class Psg.GameListItemView extends Backbone.View

  template: _.template $('#game-list-item-template').html()

  initialize: ->
    @render()

  render: ->
    @$el.append @template
      name: @model.get 'name'
      map: @model.get 'map'
      playersNum: @model.get('players').length
      maxPlayers: @model.get 'maxPlayers'
      status: @model.get 'status'


class Psg.GameListView extends Backbone.View

  tagName: 'div'
  id: 'game-list'

  template: _.template $('#game-list-template').html()

  initialize: ->
    @render()
    @listenTo @model, 'refreshed', @onRefreshed

  onRefreshed: ->
    $tbody = @$el.find('tbody')
    $tbody.empty()
    for g in @model.games.models
      new Psg.GameListItemView model: g, el: $tbody

  render: ->
    @$el.html @template()
    $content = $('#content')
    $content.empty()
    $content.append @$el
