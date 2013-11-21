window.conn = new Psg.GameConnection(config.gameUrl)
window.expect = chai.expect

window.startTesting = (done) ->
  conn.startTesting(config.websocketMode).then (data) ->
    if data.result isnt "ok"
      throw new Error('Could not start testing')
    done()
