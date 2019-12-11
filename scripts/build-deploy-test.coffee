# Description:
#   build deply test workflow
#
# Dependencies:
#
#
# Configuration:
#
#
# Commands:
#
# Notes:
#
# Author:
#   craigrigdon

mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE
ocTestNamespace = process.env.HUBOT_TEST_NAMESPACE

request = require('./request.coffee')
api = new request.OCAPI(domain, apikey)

#---------------Supporting Functions-------------------

getTimeStamp = ->
  date = new Date()
  timeStamp = date.getFullYear() + "/" + (date.getMonth() + 1) + "/" + date.getDate() + " " + date.getHours() + ":" +  date.getMinutes() + ":" + date.getSeconds()
  RE_findSingleDigits = /\b(\d)\b/g
  # Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )

buildDeploySync = (ocBuildProject, buildConfig, ocDeployProject, deployConfig) ->

    console.log("build project: #{ocBuildProject}")
    console.log("deploy project: #{ocDeployProject}")
    retVal = await api.buildSync(ocBuildProject, buildConfig) # returns promise
    # what you want to do with the build sync
    console.log('---complete---')
    console.log("#{JSON.stringify(retVal)}")
    console.log("#{typeof retVal}")

    console.log("----- running deploy now -----")
    deployStatus =  await api.deployLatest(ocBuildProject, buildConfig, ocDeployProject, deployConfig)
    console.log "DEPLY STATUS: #{deployStatus}"
    console.log JSON.stringify(deployStatus)
    await return deployStatus

#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "build-deploy-test", (obj) ->

    console.log "object passed is  : #{JSON.stringify(obj)}"

    # -------------- STAGE Build/Deploy ------------
    # start build deploy watch
    stage = "build-and-deploy"

    # message
    mesg = "Build and Deploy for #{obj.repoName} #{obj.commitID} " + getTimeStamp()

    # send message to chat
    robot.messageRoom mat_room, mesg

    # update brain
    event = robot.brain.get(obj.commitID)
    event.entry.push mesg

    # call build/deploy watch
    resp = await buildDeploySync(obj.build.namespace, obj.build.buildconfig, obj.deploy.namespace, obj.deploy.deployconfig)

    console.log "your response is : #{JSON.stringify(resp)}"
    console.log resp.statuses

    deploydStatus = resp.statuses.deploy.status
    deployKind = resp.statuses.deploy.payload.kind
    deployName = resp.statuses.deploy.payload.metadata.name
    deployCreationTimestamp = resp.statuses.deploy.payload.metadata.creationTimestamp
    deployUID = resp.statuses.deploy.payload.metadata.uid

    # message
    mesg = "#{deployKind} #{deploydStatus} #{deployName} #{deployCreationTimestamp} #{deployUID}"
    console.log mesg

    # update brain
    event = robot.brain.get(obj.repoName)
    event.entry.push mesg

    switch envKey
      when "dev"
        event.stage.dev.deploy_status.push deploydStatus
        event.stage.dev.deploy_uid.push deployUID

      when "test"
        event.stage.test.deploy_status.push deploydStatus
        event.stage.test.deploy_uid.push deployUID

    # send message to chat
    robot.messageRoom mat_room, "#{mesg}"

    #----------------STAGE TEST----------------------
    if deploydStatus == "success"
      stage = "Testing"

      switch obj.envKey
        when "dev"
         templateUrl = devApiTestTemplate
        when 'test'
         templateUrl = testApiTestTemplate
        else
         templateUrl = null
         console.log "failed to set templateURL"
         return
      #TODO: err check args and exit , let chat room know
      console.log "Test against environment #{obj.envKey}"

      # get job template from repo
      robot.http(templateUrl)
        .header('Accept', 'application/json')
        .get() (err, httpres, body) ->

          # check for errs
          if err
            console.log "Encountered an error :( #{err}"
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

          #add env var with ID of deployment for tracking
          data =  {"name": "DEPLOY_UID","value": deployUID}
          console.log "#{JSON.stringify(data)}"
          console.log "add new data to job yaml"
          job.spec.template.spec.containers[0].env.push data
          console.log "#{JSON.stringify(job)}#"

          # send job to ocp api jobs endpoint in test frame work namespace
          robot.http("https://#{domain}/apis/batch/v1/namespaces/#{ocTestNamespace}/jobs")
           .header('Accept', 'application/json')
           .header('Authorization', "Bearer #{apikey}")
           .post(JSON.stringify(job)) (err, httpRes, body2) ->
            # check for errs
            if err
              console.log "Encountered an error sending job to ocp :( #{err}"
              return

            data = JSON.parse body2
            console.log "returning ocp jobs response"
            console.log data

            # check for ocp returned status responses.
            if data.kind == "Status"
              status = data.status
              reason = data.message
              console.log "#{status} #{reason} "
              return

            #continue and message back succesful resp details
            kind = data.kind
            buildName = data.metadata.name
            namespace = data.metadata.namespace
            time = data.metadata.creationTimestamp

            mesg = "Starting #{kind} #{buildName} in #{namespace} at #{time}"
            console.log mesg

            # update brain
            event = robot.brain.get(obj.repoName)
            event.entry.push mesg

            # send message to chat
            robot.messageRoom mat_room, "#{mesg}"


            #hubot will now wait for test results recieved from another defined route in hubot.
