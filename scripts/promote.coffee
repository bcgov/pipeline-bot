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

matRoom = process.env.HUBOT_MATTERMOST_CHANNEL


#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "promote", (obj) ->
  #expecting obj as event from brain

    console.log "promote has been called"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    # -------------- promote is the question ------------

    env = obj.event.env
    stage = obj.event.stage[env]

    console.log "object to promote : #{JSON.stringify(stage)}"
    if stage.deploy_status == "success" && stage.test_status == "Passed" && stage.promote == false

      mesg = "promoting #{obj.event.repoFullName}"
      console.log mesg

      # message room
      robot.messageRoom matRoom, "#{mesg}"

      #update brain
      entry = mesg
      obj.event.entry.push entry
      stage.promote = true

      # check if prod, if so stop and complete else continue on as planned
      if env != "prod"
        robot.emit "github-pr", {
          event    : obj, #event object from brain
        }
      else

        mesg = "Completed Pipeline #{obj.event.repoFullName}"
        console.log mesg

        # message room
        robot.messageRoom matRoom, "#{mesg}"

        obj.event.status = "completed"
        obj.event.entry.push entry

      return
    else
      mesg = "Do Not promote #{obj.event.repoFullName}"
      console.log mesg

      # message room
      robot.messageRoom matRoom, "#{mesg}"

      #update brain
      entry = mesg
      obj.event.entry.push entry
      stage.promote  = false
      obj.event.status = "failed"

