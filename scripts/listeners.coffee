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
   robot.hear /autobot ready/i, (res) ->
     gif = "![GIF for ' autobot'](https://thumbs.gfycat.com/AfraidScalyDore-size_restricted.gif)"
     res.reply gif
     res.reply "READY"

   # used to check if bot is up.
   robot.hear /hey bot split/i, (res) ->
     gif = "![GIF for ' best bot'](https://media3.giphy.com/media/3ndAvMC5LFPNMCzq7m/100.gif)"
     res.reply gif
     res.reply gif
