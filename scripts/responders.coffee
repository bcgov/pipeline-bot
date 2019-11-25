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
#   pipeline-bot test <[dev|test]>  <project> - run api test against dev/test in OCP projectspace
#   pipeline-bot builddeploy <buildConfig> <project> - start OCP build/deploy and watch
#
# Notes:
#
#
# Author:
#   craigrigdon

mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE

request = require('./request.coffee')

api = new request.OCAPI(domain, apikey)

buildSync = (project, buildConfig) ->
    console.log("project: #{project}")
    retVal = await api.buildSync(project, buildConfig) # returns promise
    # what you want to do with the build sync
    console.log('---complete---')
    console.log("#{JSON.stringify(retVal)}")
    console.log("#{typeof retVal}")
    await return retVal


buildDeploySync = (project, buildConfig, deployConfig) ->

    console.log("project: #{project}")

    retVal = await api.buildSync(project, buildConfig) # returns promise
    # what you want to do with the build sync
    console.log('---complete---')
    console.log("#{JSON.stringify(retVal)}")
    console.log("#{typeof retVal}")

    console.log("----- running deploy now -----")
    deployStatus =  await api.deployLatest(project, buildConfig, deployConfig)
    console.log "DEPLY STATUS: #{deployStatus}"
    console.log JSON.stringify(deployStatus)
    await return deployStatus



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


#   # Build example
#   robot.respond /build (.*) (.*)/i, (res) ->
#     # pipeline-bot build <configName> <project>
#     config = res.match[1]
#     project = res.match[2]
#     console.log "#{config} #{project}"
#
#     robot.http("https://#{domain}/apis/build.openshift.io/v1/namespaces/#{project}/buildconfigs/#{config}/instantiate")
#       .header('Accept', 'application/json')
#       .header("Authorization", "Bearer #{apikey}")
#       .post(JSON.stringify({
#        kind: "BuildRequest", apiVersion: "build.openshift.io/v1", metadata: {name:"#{config}", creationTimestamp: null}, triggeredBy: [{message: "Triggered by Bot"}], dockerStrategyOptions: {}, sourceStrategyOptions: {}
#      })) (err, httpRes, body) ->
#        # check for errs
#        if err
#          res.reply "Encountered an error :( #{err}"
#          return
#
#        data = JSON.parse body
#        console.log data
#
#        # check for ocp returned status responses.
#        if data.kind == "Status"
#          status = data.status
#          reason = data.message
#          res.reply "#{status} #{reason} "
#          return
#
#        #continue and message back succesful resp details
#        kind = data.kind
#        buildName = data.metadata.name
#        namespace = data.metadata.namespace
#        time = data.metadata.creationTimestamp
#        phase = data.status.phase
#
#        mesg = "Starting #{phase} #{kind} #{buildName} in #{namespace} at #{time}"
#        console.log mesg
#        res.reply mesg

   # start OCP job from template - api-test
   robot.respond /test (.*) (.*)/i, (res) ->
     # pipeline-bot test <[dev|test]>  <project> - run api test against dev/test in OCP projectspace
     env = res.match[1].toLowerCase()
     project = res.match[2].toLowerCase()

     if env == 'dev'
        templateUrl = devApiTestTemplate
     else if env == 'test'
        templateUrl = testApiTestTemplate
     else
        templateUrl = ""
        console.log "failed to set templateURL"
        res.reply "please provide envrioment option dev/test"
        return
     #TODO: err check args and exit
     console.log env

     robot.http(templateUrl)
       .header('Accept', 'application/json')
       .get() (err, httpres, body) ->

         # check for errs
         if err
           res.reply "Encountered an error :( #{err}"
           return

         fs = require('fs')
         yaml = require('js-yaml')

         data = yaml.load(body)
         jsonString = JSON.stringify(data)
         jsonParsed = JSON.parse(jsonString)
         # get job object from template
         # TODO: check if kind is of job type
         job = jsonParsed.objects[0]
         console.log job

         # send job to ocp api jobs endpoint
         robot.http("https://#{domain}/apis/batch/v1/namespaces/#{project}/jobs")
          .header('Accept', 'application/json')
          .header('Authorization', "Bearer #{apikey}")
          .post(JSON.stringify(job)) (err, httpRes, body2) ->
           # check for errs
           if err
             res.reply "Encountered an error :( #{err}"
             return

           data = JSON.parse body2
           console.log "returning jobs response"
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

           mesg = "Starting #{kind} #{buildName} in #{namespace} at #{time}"
           console.log mesg
           res.reply mesg


   #build and watch
   robot.respond /build (.*) (.*)/i, (res) ->
     # pipeline-bot build <buildConfig> <project> - start OCP build and watch
     buildConfig = res.match[1].toLowerCase()
     project = res.match[2].toLowerCase()
     res.reply "Lets start building #{buildConfig}"
     resp = await buildSync(project, buildConfig)
     console.log "your response is : #{JSON.stringify(resp)}"

     console.log resp.statuses
     status = resp.statuses.build.status
     kind = resp.statuses.build.payload.kind
     name = resp.statuses.build.payload.metadata.name
     creationTimestamp = resp.statuses.build.payload.metadata.creationTimestamp
     commit = resp.statuses.build.payload.spec.revision.git.commit
     mesg = "Commit #{commit} #{status} #{kind} #{name} #{creationTimestamp}"
     console.log mesg
     res.reply mesg


   #build and deploy
   robot.respond /builddeploy (.*) (.*)/i, (res) ->
     # pipeline-bot builddeploy <buildConfig> <project> - start OCP build/deploy and watch
     buildConfig = res.match[1].toLowerCase()
     project = res.match[2].toLowerCase()
     deployConfig = buildConfig  # hardcoded for testing at this time.

     # message
     mesg = "Start build and deploy for #{buildConfig}"

     # send mesg
     res.reply mesg

     # add to brain
     robot.brain.set('BuildandDeploy', { entry: [mesg]})

     # call build/deploy watch
     resp = await buildDeploySync(project, buildConfig, deployConfig)
     console.log "your response is : #{JSON.stringify(resp)}"



     #TODO: add parsing to function outside to minimize code.
     buildStatus = resp.statuses.build.status
     buildKind = resp.statuses.build.payload.kind
     buildName = resp.statuses.build.payload.metadata.name
     buildCreationTimestamp = resp.statuses.build.payload.metadata.creationTimestamp
     buildUID = resp.statuses.deploy.payload.metadata.uid

     # message
     mesg = "#{buildKind} #{buildStatus} #{buildName} #{buildCreationTimestamp} #{buildUID} "
     console.log mesg

     # add to brain
     event = robot.brain.get('BuildandDeploy')
     event.entry.push mesg

     # send message to chat
     res.reply mesg

     deploydStatus = resp.statuses.deploy.status
     deployKind = resp.statuses.deploy.payload.kind
     deployName = resp.statuses.deploy.payload.metadata.name
     deployCreationTimestamp = resp.statuses.deploy.payload.metadata.creationTimestamp
     deployUID = resp.statuses.deploy.payload.metadata.uid

     # message
     mesg = "#{deployKind} #{deploydStatus} #{deployName} #{deployCreationTimestamp} #{deployUID} "
     console.log mesg

     # add to brain
     event = robot.brain.get('BuildandDeploy')
     event.entry.push mesg

     # send message to chat
     res.reply mesg

