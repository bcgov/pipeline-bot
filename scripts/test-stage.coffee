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

matroom = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE
ocTestNamespace = process.env.HUBOT_TEST_NAMESPACE # TODO: need to define this else where


#---------------Supporting Functions-------------------

getTimeStamp = ->
  date = new Date()
  timeStamp = date.getFullYear() + "/" + (date.getMonth() + 1) + "/" + date.getDate() + " " + date.getHours() + ":" +  date.getMinutes() + ":" + date.getSeconds()
  RE_findSingleDigits = /\b(\d)\b/g
  # Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )

#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "test-stage", (obj) ->
    # expecting the following from obj

    # repoFullName # repo name from github payload
    # eventStage # stage object from memory to update
    # envKey # enviromnet key from github action param
    console.log "Called test-stage script"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    #----------------API TEST----------------------

    # exhaustive switch of test templates
    switch obj.envKey
      when "dev"
       templateUrl = devApiTestTemplate
      when 'test'
       templateUrl = testApiTestTemplate
      when "stage"
       templateUrl = null
      when 'prod'
       templateUrl = null
      else
       console.log "failed to set api test templateURL"
       templateUrl = null
       return

    try
      # if templateURL has been set, call job to be created.
      # TODO: migrate from template to jobs.yaml
      if templateUrl

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
                robot.messageRoom matroom, "#{mesg}"

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
                robot.messageRoom matroom, "#{mesg}"

                #hubot will now wait for test results recieved from another defined route in hubot.

      else
        mesg = "No Test have been defined for this environment."
        console.log mesg

        # update brain
        event = robot.brain.get(obj.repoFullName)
        event.entry.push mesg
        obj.eventStage.test_status = "success"

        # send message to chat
        robot.messageRoom matroom, "#{mesg}"

        #hubot will now continue on with promote.

        # to promote or not to promote that is the question.
        robot.emit "promote", {
            event    : event, #event object from brain
        }
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matroom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"
