# Description:
#   responders script file
#
# Dependencies:
#
#
# Configuration:
#
#
# Commands:
#   pipeline-bot deploy <configName> <project> - start deployment config in OCP project space
#   pipeline-bot build <configName> <project> - start buildconfig in OCP project space
#   pipeline-bot mission - get pipeline-bots mission in life
#   pipeline-bot status <repo/name> - get status of pipeline
#   pipeline-bot list - get list of repos in pipeline
#   pipeline-bot test <[cati|cadi]> - run api test against cati/cadi
#
#
# Notes:
#
#
# Author:
#   craigrigdon

mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN


module.exports = (robot) ->

   # state your mission
   robot.respond /mission/i, (res) ->
     res.reply 'I am a CI/CD Pipeline Tool.  I will monitor and orchestrate deployments. Feel free to check-in on me anytime by using "pipeline-bot status <repo/name>"'

   # list all
   robot.respond /list/i, (res) ->
     # get all keys in brain
     keys = Object.keys(robot.brain.data._private)
     console.log keys

     if keys.length > 0
        mesg = "pipelines in progress: #{JSON.stringify(keys)}"
     else
        mesg = "no pipelines in progress"

     res.reply mesg

   robot.respond /status (.*)/i, (res) ->
     repo = res.match[1]
     console.log "#{repo}"

     # get
     event = robot.brain.get(repo)

     if event?
        mesg = "#{JSON.stringify(event)}"
     else
        mesg = "sorry nothing here by that name, try 'pipeline-bot list' to show all repos in pipeline"

     res.reply mesg

   # Deploy example
   robot.respond /deploy (.*) (.*)/i, (res) ->
     # pipeline-bot deploy <configName> <project>
     config = res.match[1]
     project = res.match[2]
     console.log "#{config} #{project}"

     robot.http("https://#{domain}/apis/apps.openshift.io/v1/namespaces/#{project}/deploymentconfigs/#{config}/instantiate")
       .header('Accept', 'application/json')
       .header("Authorization", "Bearer #{apikey}")
       .post(JSON.stringify({
        kind :"DeploymentRequest", apiVersion:"apps.openshift.io/v1", name:"#{config}", latest :true, force :true
      })) (err, httpres, body) ->
        # check for errs
        if err
          res.reply "Encountered an error :( #{err}"
          return

        data = JSON.parse body
        console.log data

        # check for ocp returned status responses.
        if data.kind == "Status"
          status = data.status
          reason = data.message
          res.reply "#{status} #{reason} "
          return

        #continue and message back succesful resp details
        kind = data.kind
        deployName = data.metadata.name
        namespace = data.metadata.namespace
        time = data.metadata.creationTimestamp
        version = data.status.latestVersion

        mesg = "Starting  #{kind} #{deployName} #{version} in #{namespace} at #{time}"
        console.log mesg
        res.reply mesg


   # Build example
   robot.respond /build (.*) (.*)/i, (res) ->
     # pipeline-bot build <configName> <project>
     config = res.match[1]
     project = res.match[2]
     console.log "#{config} #{project}"

     robot.http("https://#{domain}/apis/build.openshift.io/v1/namespaces/#{project}/buildconfigs/#{config}/instantiate")
       .header('Accept', 'application/json')
       .header("Authorization", "Bearer #{apikey}")
       .post(JSON.stringify({
        kind: "BuildRequest", apiVersion: "build.openshift.io/v1", metadata: {name:"#{config}", creationTimestamp: null}, triggeredBy: [{message: "Triggered by Bot"}], dockerStrategyOptions: {}, sourceStrategyOptions: {}
      })) (err, httpRes, body) ->
        # check for errs
        if err
          res.reply "Encountered an error :( #{err}"
          return

        data = JSON.parse body
        console.log data

        # check for ocp returned status responses.
        if data.kind == "Status"
          status = data.status
          reason = data.message
          res.reply "#{status} #{reason} "
          return

        #continue and message back succesful resp details
        kind = data.kind
        buildName = data.metadata.name
        namespace = data.metadata.namespace
        time = data.metadata.creationTimestamp
        phase = data.status.phase

        mesg = "Starting #{phase} #{kind} #{buildName} in #{namespace} at #{time}"
        console.log mesg
        res.reply mesg

   # start OCP job from template - api-test
   robot.respond /test/i, (res) ->
#   /test (.*) (.*)/i
     # pipeline-bot test <[cati|cadi]> - run api test against cati/cadi
     env = res.match[1]
     project = "databcdc"
     console.log env

     templateUrl = 'https://raw.githubusercontent.com/bcgov/bcdc-test/dev/k8s/test-dwelf-job-template-dev.yaml'

     robot.http(templateUrl)
       .header('Accept', 'application/json')
       .get() (err, httpres, body) ->

         # check for errs
         if err
           res.reply "Encountered an error :( #{err}"
           return

         fs = require('fs')
         yaml = require('js-yaml')
         payload = yaml.safeLoad(fs.readFileSync('./test-dwelf-job-dev.yaml', 'utf8'))
         console.log payload



         robot.http("https://#{domain}/apis/batch/v1/namespaces/#{project}/jobs")
          .header('Accept', 'application/json')
          .header('Authorization', "Bearer #{apikey}")
          .post(JSON.stringify(payload)) (err, httpRes, body2) ->
           # check for errs
           if err
             res.reply "Encountered an error :( #{err}"
             return

           data = JSON.parse body2
           console.log "jobs"
           console.log data

           # check for ocp returned status responses.
           if data.kind == "Status"
             status = data.status
             reason = data.message
             res.reply "#{status} #{reason} "
             return

           #continue and message back succesful resp details
           kind = data.kind
           buildName = data.metadata.name
           namespace = data.metadata.namespace
           time = data.metadata.creationTimestamp

