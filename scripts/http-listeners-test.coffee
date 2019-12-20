# Description:
#   test http listener srcipt
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
configPath = process.env.HUBOT_CONFIG_PATH ? 'https://raw.githubusercontent.com/bcgov/pipeline-bot/EventEmitter/config/config.json' #testing only

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

    robot.http(configPath)
       .header('Accept', 'application/json')
       .get() (err, httpres, body2) ->

       # check for errs
         if err
           res.reply "Encountered an error fetching config file :( #{err}"
           return

         pipes = JSON.parse(body2)
         console.log pipes

         buildObj = null
         deployObj = null

         env = "dev"

         for pipe in pipes.pipelines
           console.log "#{JSON.stringify(pipe.name)}"
           if pipe.name == "datapusher"
             console.log "Repo found in conifg map: #{JSON.stringify(pipe.name)}"

             switch env
               when "dev"
                 console.log "define vars for dev"
                 console.log "#{JSON.stringify(pipe.dev)}"
                 buildObj = pipe.dev.build
                 deployObj = pipe.dev.deploy

               when "test"
                 console.log "define vars for test"
                 console.log "#{JSON.stringify(pipe.test)}"
                 buildObj = pipe.test.build
                 deployObj = pipe.test.deploy

         console.log "#{JSON.stringify(buildObj)}"
         console.log "#{JSON.stringify(deployObj)}"

