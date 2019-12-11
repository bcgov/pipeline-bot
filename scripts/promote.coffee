# Description:
#   promote logic
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


#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "promote", (event) ->

    console.log "promote has been called"
    console.log "object passed is  : #{JSON.stringify(event)}"

    # -------------- promote is the question ------------

    if event.passedTest == true

