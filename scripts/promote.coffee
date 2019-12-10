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

  robot.on "promote", (obj) ->

    console.log "promote has been called"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    # -------------- promote is the question ------------

