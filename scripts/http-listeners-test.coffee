# Description:
#   http listener srcipt to create endpoint to be used by exteral services to notify hubot of status
#
# Created by:
#   craigrigdon
#
# Notes:
#   Hubot includes support for the express web framework to serve up HTTP requests.
#   It listens on the port specified by the EXPRESS_PORT or PORT environment variables (preferred in that order)
#   and defaults to 8080. An instance of an express application is available at robot.router.
#   It can be protected with username and password by specifying EXPRESS_USER and EXPRESS_PASSWORD.
#   It can automatically serve static files by setting EXPRESS_STATIC.

module.exports = (robot) ->
#  # example:
#  # the expected value of :room is going to vary by adapter, it might be a numeric id, name, token, or some other value
#  robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
#    room   = req.params.room
#    data   = if req.body.payload? then JSON.parse req.body.payload else req.body
#    secret = data.secret
#
#    robot.messageRoom room, "I have a secret: #{secret}"
#
#    res.send 'OK'
