mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
project = 'databcdc'
buildConfig = 'pipeline-bot'

module.exports = (robot) ->

   robot.respond /mission/i, (res) ->
     res.reply 'I am a CI/CD Pipeline Tool.  I will monitor and orchestrate deployments. Feel free to check-in on me anytime by using "pipeline-bot status"'

   robot.respond /status/i, (res) ->
     res.reply 'Nothing to report. Currently under development at this time.'


   #demo ONLY to be removed
   robot.respond /deploy pipeline-bot/i, (res) ->
     res.reply 'Deploying myself now.'

     robot.http("https://console.pathfinder.gov.bc.ca:8443/apis/apps.openshift.io/v1/namespaces/#{project}/deploymentconfigs/#{buildConfig}/instantiate")
       .header('Accept', 'application/json')
       .header("Authorization", "Bearer #{apikey}")
       .post(JSON.stringify({
        kind :"DeploymentRequest", apiVersion:"apps.openshift.io/v1", name:"pipeline-bot", latest :true, force :true
      })) (err, res, body) ->
          # error checking code here

        data = JSON.parse body
        console.log data

   #demo ONLY to be removed
   robot.respond /build pipeline-bot/i, (res) ->
     res.reply 'Building myself now.'

     robot.http("https://console.pathfinder.gov.bc.ca:8443/apis/build.openshift.io/v1/namespaces/#{project}/buildconfigs/#{buildConfig}/instantiate")
       .header('Accept', 'application/json')
       .header("Authorization", "Bearer #{apikey}")
       .post(JSON.stringify({
        kind: "BuildRequest", apiVersion: "build.openshift.io/v1", metadata: {name: "pipeline-bot", creationTimestamp: null}, triggeredBy: [{message: "Triggered with coffee"}], dockerStrategyOptions: {}, sourceStrategyOptions: {}
      })) (err, res, body) ->
          # error checking code here

        data = JSON.parse body
        console.log data

