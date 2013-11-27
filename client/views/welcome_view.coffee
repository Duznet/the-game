class Psg.WelcomeView extends Backbone.View

  tagName: 'div'
  className: 'lead'
  id: 'welcome'

  initialize: ->
    @render()

  render: ->
    @$el.html 'rendering'
    console.log 'rendering', @$el, @el

