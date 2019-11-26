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

mat_room = process.env.HUBOT_MATTERMOST_CHANNEL

module.exports = (robot) ->

   # used to check if bot is up.
   robot.hear /hey bot/i, (res) ->
     res.reply '/gif best bot'
