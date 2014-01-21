window.config =
  # gameUrl: "http://46.37.142.252:3000/"
  # gameplayUrl: "ws://46.37.142.252:8001/"
  gameUrl: "http://localhost:5000"
  gameplayUrl: "ws://localhost:5000/websocket"
  # gameUrl: "http://localhost:5001"
  # gameplayUrl: "ws://localhost:5001/websocket"
  # gameUrl: "http://localhost:3000"
  # gameplayUrl: "ws://localhost:8001"
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

