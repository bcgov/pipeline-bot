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

# get mattermost channel from env var passed to container on deployment
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
route = '/hubot/github'

module.exports = (robot) ->

  robot.router.post route, (req, res) ->
    console.log route
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
#    console.log data

    commits = data.commits
    pusher = data.pusher.name
    ref = data.ref

#    console.log data.commits
    console.log "Recieved #{commits} by #{pusher} for #{ref}"

#   robot.messageRoom mat_room, "#{env} #{stage} #{status}"
    status = "Success"
    res.send status

