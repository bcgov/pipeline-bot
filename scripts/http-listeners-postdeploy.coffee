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
matroom = process.env.HUBOT_MATTERMOST_CHANNEL
route = '/hubot/postdeploy'

module.exports = (robot) ->

  robot.router.post route, (req, res) ->

    # expecting example payload of {"status":"success", "env":"cadi", "results":"results", "id":"12345ABC"}'
    console.log route
    console.log "Called http-listeners-postdeploy script"

    stage = "Post-Deployment"

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    status = data.status
    env = data.env
    results = data.results
    id = data.id
    console.log "ID returned with #{stage} payload: #{id}"

    # build message
    mesg = "#{stage} #{status} #{env} #{JSON.stringify(results)}"
    console.log mesg

    # send message
    robot.messageRoom matroom, "#{mesg}"

    # ------------- Search Brain for Deployment ID----------------
    # Search for keys with id matching deployment id in all stages and update brian
    try
      keys = Object.keys(robot.brain.data._private)
      console.log keys

      for key in keys
        event = robot.brain.get(key)
        console.log JSON.stringify(event)

        stages = Object.keys(event.stage)
        console.log "list of stages : #{JSON.stringify(stages)}"

        for stage in stages
          obj = event.stage[stage]
          console.log "object to search : #{JSON.stringify(obj)}"
          if obj.deploy_uid == id
            console.log "found #{id} in #{JSON.stringify(obj)}"

            #update brain
            event = robot.brain.get(key)
            entry = mesg
            event.entry.push entry
            obj.postdeploy_status = status

            if status == "success"
              console.log "Sending pipeline #{JSON.stringify(event.repoFullName)} to Test Stage"
              robot.emit "test-stage", {
                 repoFullName    : event.repoFullName, # repo full name from github payload
                 eventStage : event.eventStage, # stage object from memory to update
                 envKey : event.envKey, # enviromnet key from github action param
              }
            else
              mesg = "#{stage} #{status} for #{JSON.stringify(event.repoFullName)}. Pipeline has Stopped"

            #update brain
            entry = mesg
            event.entry.push entry

          else
            console.log "did not find #{id} in #{JSON.stringify(obj)}"


      # TODO: error check and return status
      status = "Success"
      res.send status
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matroom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"


