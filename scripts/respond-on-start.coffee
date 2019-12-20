# Description
#   A Hubot script that greets us when this script loaded.
#
# Configuration:
#
# Commands:
#   None
#
# Author:
#   craigrigdon
#
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL

module.exports = (robot) ->
  mesg = "#{robot.name} is now Ready #{new Date()}!"
  robot.messageRoom mat_room, "#{mesg}"
