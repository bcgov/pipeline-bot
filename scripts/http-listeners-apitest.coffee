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

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    status = data.status
    env = data.env
    results = data.results

    # build message
    mesg = "API Test Results: #{status} #{env} #{JSON.stringify(results)}"
    console.log mesg

#    # TODO get reponame somehow
#    repoName = ()
#    # add to brain
#    robot.brain.set(repoName, {mesg: mesg, timestamp: timestamp})

    # send message
    robot.messageRoom mat_room, "#{mesg}"

    # TODO: error check and return status
    status = "Success"
    res.send status
