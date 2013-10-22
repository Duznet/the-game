window.config =
  url: "/"
  gameUrlSuffix: "/websocket"

  getDefaultUrl: ->
    @url
  getGameUrl: ->
    "#{@url}#{if @url.charAt(@url.length - 1) == '/' then '' else '/'}#{@gameUrlSuffix}"
