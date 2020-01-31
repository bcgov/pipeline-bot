# Description:
#   teststage workflow
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

#TODO: convert to job yamls only and reference paths in config map in ocp

testPostDeployTemplate = process.env.HUBOT_TEST_POSTDEPLOY_TEMPLATE
stagePostDeployTemplate = process.env.HUBOT_STAGE_POSTDEPLOY_TEMPLATE

ocTestNamespace = process.env.HUBOT_TEST_NAMESPACE # TODO: need to define this else where

#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "post-deploy-stage", (obj) ->
    # expecting the following from obj

    # repoFullName # repo name from github payload
    # eventStage # stage object from memory to update
    # envKey # enviromnet key from github action param

    console.log "object passed is  : #{JSON.stringify(obj)}"

    #----------------Post Deployment Jobs----------------------

    # exhaustive switch of test templates
    switch obj.envKey
      when "dev"
       templateUrl = null
      when 'test'
       templateUrl = testPostDeployTemplate
      when "stage"
       templateUrl = stagePostDeployTemplate
      when 'prod'
       templateUrl = null
      else
       console.log "failed to set post deploy templateURL"
       templateUrl = null
       return

    # if templateURL has been set, call job to be created.
    # TODO: migrate from template to jobs.yaml
    if templateUrl

      console.log "Post Deployment Job against environment #{obj.envKey}"

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
          data =  {"name": "DEPLOY_UID","value": obj.eventStage.deploy_uid}
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
              mesg = "Failed to Start API Test #{status} #{reason}"
              console.log mesg

              # update brain
              event = robot.brain.get(obj.repoFullName)
              event.entry.push mesg
              obj.eventStage.test_status = "failed"

              # send message to chat
              robot.messageRoom mat_room, "#{mesg}"

            else if data.kind == "Job"
              kind = data.kind
              buildName = data.metadata.name
              namespace = data.metadata.namespace
              time = data.metadata.creationTimestamp

              mesg = "Starting #{kind} #{buildName} in #{namespace} at #{time}"
              console.log mesg

              # update brain
              event = robot.brain.get(obj.repoFullName)
              event.entry.push mesg
              obj.eventStage.test_status = "pending"

              # send message to chat
              robot.messageRoom mat_room, "#{mesg}"

              #hubot will now wait for test results recieved from another defined route in hubot.

    else
      mesg = "No Post Deployment Jobs have been defined for this environment."
      console.log mesg

      # update brain
      event = robot.brain.get(obj.repoFullName)
      event.entry.push mesg
      obj.eventStage.postdeploy_status = "success"

      # send message to chat
      robot.messageRoom mat_room, "#{mesg}"

      #hubot will now continue on with promote.

      # to promote or not to promote that is the question.
      console.log "Sending pipeline #{JSON.stringify(event.repoFullName)} to promote logic"
      robot.emit "promote", {
          event    : event, #event object from brain
      }

