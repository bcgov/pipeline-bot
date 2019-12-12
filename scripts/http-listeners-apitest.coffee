# Description:
#   http listener for bcdc-api test payload
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
route = '/hubot/apitest'

module.exports = (robot) ->

  robot.router.post route, (req, res) ->

    console.log route
    stage = "API-TEST"

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    status = data.status
    env = data.env
    results = data.results
    id = data.id
    console.log "ID returned with api test result payload:  #{id}"

    # build message
    mesg = "#{stage} #{status} #{env} #{JSON.stringify(results)}"
    console.log mesg

    # send message
    robot.messageRoom matRoom, "#{mesg}"

    # ------------- Search Brain for Deployment ID----------------
    # Search for keys with id matching deployment id in all stages and update brian

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
          obj.test_status = status

          # to promote or not to promote that is the question.
          console.log "Sending pipeline #{JSON.stringify(event.repo)} to promote logic"
          robot.emit "promote", {
              event    : event, #event object from brain
          }
          return
        else
          console.log "did not find #{id} in #{JSON.stringify(obj)}"


    # TODO: error check and return status
    status = "Success"
    res.send status



