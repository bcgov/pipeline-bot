# Description:
#   test http listener srcipt to create endpoint to be used by exteral services to notify hubot of status,
#   will print payload to console and send success back.
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
#mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
route = '/hubot/test'
pipelineMap = process.env.HUBOT_PIPELINE_MAP

module.exports = (robot) ->
  # example how to use params
  # example with param: robot.router.post '/hubot/test/:channeName', (req, res) ->
  # example call: http://127.0.0.1:8080/hubot/test/channeName
  # examble to retrive in function: channeName  = req.params.channeName

  robot.router.post route, (req, res) ->
    console.log route
    data   = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log "Payload is: #{JSON.stringify(data)}"


    status = "Success"
    res.send status


    console.log pipelineMap

    pipes = (JSON.parse(pipelineMap))
    console.log pipes
    for pipe in pipes.pipelines
      console.log "#{JSON.stringify(pipe.name)}"
      if pipe.name == "datapusher"
        console.log "found it: #{JSON.stringify(pipe.name)}"
