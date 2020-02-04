# Description:
#   listener script file
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

matroom = process.env.HUBOT_MATTERMOST_CHANNEL

module.exports = (robot) ->

   # used to check if bot is up.
   robot.hear /autobot ready/i, (res) ->
     res.reply "READY"

