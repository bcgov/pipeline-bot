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

   # used to check if bot is up.
   robot.hear /autobot attach/i, (res) ->

     msg = {}
     test = {"attachments": [{"fallback": "test","color": "#FF8000","pretext": "pretext","text": "text",\
     "author_name": "author_name","author_icon": "http://www.mattermost.org/wp-content/uploads/2016/04/icon_WS.png",\
     "author_link": "http://www.mattermost.org/","title": "title",\
     "title_link": "http://docs.mattermost.com/developer/message-attachments.html",\
     "fields": [{"short": true,"title": "Stage","value": "Stage Name Here"},\
     {"short": true,"title": "Status","value": "Status of Stage"},\
     "image_url": "http://www.mattermost.org/wp-content/uploads/2016/03/logoHorizontal_WS.png"}]}

     msg.message = "message with attachments"
		 msg.props = {}
		 msg.props.attachments = test

     res.reply msg
