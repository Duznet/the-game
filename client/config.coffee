window.config =
  gameUrl: "http://localhost:5000"
  gameplayUrl: "ws://localhost:5000/websocket"
  websocketMode: "sync"
  debug:
    pushingViewsInfo: false
    showRequests: true
  game:
    scale: 30
    showChat: false
    showCrosshair: true
    showHealth: true
    showPlayersColors: false
    coloredMode: false
    defaultConsts:
      tickSize: 30
      accuracy: 0.000001
      accel: 0.02
      maxVelocity: 0.4
      friction: 0.02
      gravity: 0.02
  interpolate: true
  fpsCalcInterval: 250
  storage: sessionStorage
  chatRefreshInterval: 1000
  chatInitialTimeOffset: 24 * 60 * 60

