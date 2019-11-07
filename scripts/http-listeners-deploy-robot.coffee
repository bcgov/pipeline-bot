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
apikey = process.env.APIKEY
domain = process.env.DOMAIN
route = '/hubot/deployrobot'

module.exports = (robot) ->
  # example how to use params
  # example with param: robot.router.post '/hubot/test/:channeName', (req, res) ->
  # example call: http://127.0.0.1:8080/hubot/test/channeName
  # examble to retrive in function: channeName  = req.params.channeName

  robot.router.post route, (req, res) ->
    console.log route
    data   = if req.body.payload? then JSON.parse req.body.payload else req.body
#    status = data.status #pass fail
#    stage = data.stage #build deploy test
#    env =  data.env #cadi cati prod
#    console.log "#{env} #{stage} #{status}"

    project = 'databcdc'
    buildConfig = 'pipeline-bot'



    data = JSON.stringify({
      kind :"DeploymentRequest", apiVersion:"apps.openshift.io/v1", name:"pipeline-bot", latest :true, force :true
    })

    robot.http("https://console.pathfinder.gov.bc.ca:8443/apis/apps.openshift.io/v1/namespaces/#{project}/deploymentconfigs/#{buildConfig}/instantiate")
      .header('Accept', 'application/json')
      .header("Authorization", "Bearer #{apikey}")
      .post(data) (err, res, body) ->
        # error checking code here

        data = JSON.parse body
        console.log data


#    robot.messageRoom mat_room, "#{env} #{stage} #{status}"
    res.send "#{route} UP"
