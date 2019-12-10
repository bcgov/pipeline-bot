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
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
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
    console.log "ID returned is  #{id}"

    # build message
    mesg = "#{stage} #{status} #{env} #{JSON.stringify(results)}"
    console.log mesg

    # send message
    robot.messageRoom mat_room, "#{mesg}"


    # ------------- Search Brain for Deployment ID----------------
    # Search for keys with id matching deployment id and update brian
    keys = Object.keys(robot.brain.data._private)
    console.log keys

    for key in keys
      event = robot.brain.get(key)

      if event.id == id
        console.log id

        # add another entry to array
#        event = robot.brain.get(key)
        entry = mesg
        event.entry.push entry

        # to promote or not to promote that is the question.
        eventObj
        console.log "Sending pipeline #{JSON.stringify(event.repo)} to promote logic"
        robot.emit "promote", {
            event    : event, #event object from brain
        }
      else
        console.log "ID #{id} not found"

    # TODO: error check and return status
    status = "Success"
    res.send status



