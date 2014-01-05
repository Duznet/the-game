window.config =
  gameUrl: "http://localhost:5000"
  gameplayUrl: "ws://localhost:5000/websocket"
  websocketMode: "sync"
  debug:
    pushingViewsInfo: false
  game:
    scale: 30
    showChat: true
    showSight: true
    showHealth: true
    defaultConsts:
      tickSize: 30
      accuracy: 0.000001
      accel: 0.02
      maxVelocity: 0.2
      friction: 0.02
      gravity: 0.02
  interpolate: true
  fpsCalcInterval: 250
  storage: sessionStorage
  chatRefreshInterval: 1000
  chatInitialTimeOffset: 24 * 60 * 60

