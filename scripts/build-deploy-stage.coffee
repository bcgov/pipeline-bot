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

matroom = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
#devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
#testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE
#ocTestNamespace = process.env.HUBOT_TEST_NAMESPACE

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

  robot.on "build-deploy-stage", (obj) ->
    # expecting the following from obj
    # buildObj, #build object from config file
    # deployObj, #deploy object from config file
    # repoFullName # repo name from github payload
    # eventStage # stage object from memory to update
    # envKey # enviromnet key from github action param

    console.log "called build-deploy-stage script"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    # -------------- STAGE Build/Deploy ------------
    # start build deploy watch

    # message
    mesg = "Build and Deploy for #{obj.repoFullName} in  #{obj.envKey} " + getTimeStamp()

    # update brain
    event = robot.brain.get(obj.repoFullName)
    event.entry.push mesg
    obj.eventStage.deploy_status = "pending"

    # send message to chat
    robot.messageRoom matroom, mesg

    try
      # call build/deploy watch
      resp = await buildDeploySync(obj.build.namespace, obj.build.buildconfig, obj.deploy.namespace, obj.deploy.deployconfig)

      console.log "build and deploy response is : #{JSON.stringify(resp)}"
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
      event = robot.brain.get(obj.repoFullName)
      event.entry.push mesg
      obj.eventStage.deploy_status = deploydStatus
      obj.eventStage.deploy_uid = deployUID

      # send message to chat
      robot.messageRoom matroom, "#{mesg}"

      if deploydStatus == "success"
        robot.emit "post-deploy-stage", {
           repoFullName    : obj.repoFullName, # repo full name from github payload
           eventStage : obj.eventStage, # stage object from memory to update
           envKey : obj.envKey, # enviromnet key from github action param
        }
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matroom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"
