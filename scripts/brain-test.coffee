# Description:
#   brain test work
#
# Dependencies:
#
#
# Configuration:
#
#
# Commands:
#   autobot brain (<add>|<show>|<clear>)  - add test entry, show all keys and values, clear all keys
#
#
# Notes:
#   includes examples of crud operations to hubot brain
#
# Author:
#   craigrigdon


module.exports = (robot) ->



   robot.respond /brain (.*)/i, (res) ->

      arg = res.match[1].toLowerCase()

      # test data
      key = "testKey"
      id = "12345"
      stage = "testStage"
      status = "testStatus"
      entry = "testEntry"


      switch arg
        when "add"
          console.log "adding"
          robot.brain.set(key, {id: id, stage: stage, status: status, entry: [entry]})
          data = robot.brain.data._private
          console.log data
          console.log "My Brain has: #{JSON.stringify(data)}"
          res.reply "#{JSON.stringify(data)}"
        when "show"
          console.log "showing"
          data = robot.brain.data._private
          console.log data
          console.log "My Brain has: #{JSON.stringify(data)}"
          res.reply "#{JSON.stringify(data)}"
        when "clear"
          console.log "removing"
          keys = Object.keys(robot.brain.data._private)
          for key in keys
            robot.brain.remove key
          data = robot.brain.data._private
          console.log data
          console.log "My Brain has: #{JSON.stringify(data)}"
          res.reply "#{JSON.stringify(data)}"
        else
          console.log "Error Required arguments add|show|clearALL"


#       add
#      robot.brain.set(key, {id: id, stage: stage, status: status, entry: [entry]})
#
#      # get
#      event = robot.brain.get(key)
#
#      # remove
##      robot.brain.remove key
#
#      # save
#      robot.brain.save
#
#      # get all data in brain to see if it updated brain
#      data = robot.brain.data
#      console.log data
#      console.log "Now My Brain has: #{JSON.stringify(data)}"
#
#      # get all keys in brain
#      keys = Object.keys(robot.brain.data._private)
#      console.log keys
#
#      # add another entry to array
#      event = robot.brain.get(key)
#      entry = "testEntry2"
#      event.entry.push entry
#
#      # get all data in brain to see if it updated brain
#      data = robot.brain.data
#      console.log data
#      console.log "Now My Brain has: #{JSON.stringify(data)}"
#
#      # udpate value
#      event = robot.brain.get(key)
#      status = "testStatus2"
#      event.status = status

      # get all data in brain in the _private namespace
#      data = robot.brain.data._private
#      console.log data
#      console.log "Again Now My Brain has: #{JSON.stringify(data)}"
#      res.reply "#{JSON.stringify(data)}"
