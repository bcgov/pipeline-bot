# Description:
#   http listener for post deployment task payload
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
#
# Author:
#   craigrigdon

# get mattermost channel from env var passed to container on deployment
matRoom = process.env.HUBOT_MATTERMOST_CHANNEL
route = '/hubot/jenkins'

module.exports = (robot) ->

  robot.router.post route, (req, res) ->

    console.log route
    console.log "Called http-listeners-jenkins script"
    stage = "Jenkins"

    #expecting Jenkins Payload
    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    status = data.build.status.toLowerCase()
    results = data.build.phase
    id = data.url
    console.log "ID returned with #{stage} payload: #{id}"

    # build message
    mesg = "#{stage} #{status} #{JSON.stringify(results)}"
    console.log mesg

    # send message
    robot.messageRoom matRoom, "#{mesg}"

    # ------------- Search Brain for jenkins job name ----------------
    # Search for keys with id matching jenkins_job in all stages and update brian

    try
      keys = Object.keys(robot.brain.data._private)
      console.log keys

      for key in keys
        event = robot.brain.get(key)
        console.log JSON.stringify(event)

        stages = Object.keys(event.stage)
        console.log "list of stages : #{JSON.stringify(stages)}"

        for stage in stages
          eventStage = event.stage[stage]
          console.log "object to search : #{JSON.stringify(eventStage)}"
          if eventStage.jenkins_job == id
            console.log "found #{id} in #{JSON.stringify(eventStage)}"

            #update brain
            event = robot.brain.get(key)
            entry = mesg
            event.entry.push entry
            eventStage.deploy_status = status


            #check status and send to test-stage
            if status == "success"
              mesg = "Sending pipeline #{JSON.stringify(event.repoFullName)} to Test Stage"
              robot.emit "post-deploy-stage", {
                 repoFullName    : event.repoFullName, # repo full name from github payload
                 eventStage : eventStage, # stage object from memory to update
                 envKey : event.env, # enviromnet key
              }
            else
              mesg = "#{stage} #{status} for #{JSON.stringify(event.repoFullName)}. Pipeline has Stopped"

            #update brain
            entry = mesg
            event.entry.push entry

          else
            console.log "did not find #{id} in #{JSON.stringify(eventStage)}"


      # TODO: error check and return status
      status = "Success"
      res.send status
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matRoom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"


