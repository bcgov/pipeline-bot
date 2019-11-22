# Description:
#   brain work
#
# Dependencies:
#
#
# Configuration:
#
#
# Commands:

#
#
# Notes:
#   examples of crud operations to hubot brain
#
# Author:
#   craigrigdon


module.exports = (robot) ->



   robot.respond /brain/i, (res) ->


      key = "testKey"
      id = "testId"
      stage = "testStage"
      status = "testStatus"
      entry = "testEntry"

      # add
      robot.brain.set(key, {id: id, stage: stage, status: status, entry: [entry]})

      # get
      event = robot.brain.get(key)

      # remove
#      robot.brain.remove key

      # save
      robot.brain.save

      # get all data in brain to see if it updated brain
      data = robot.brain.data
      console.log data
      console.log "Now My Brain has: #{JSON.stringify(data)}"

      # get all keys in brain
      keys = Object.keys(robot.brain.data._private)
      console.log keys

      # add another entry to array
      event = robot.brain.get(key)
      entry = "testEntry2"
      event.entry.push entry

      # get all data in brain to see if it updated brain
      data = robot.brain.data
      console.log data
      console.log "Now My Brain has: #{JSON.stringify(data)}"

      # udpate value
      event = robot.brain.get(key)
      status = "testStatus2"
      event.status = status

      # get all data in brain to see if it updated brain
      data = robot.brain.data
      console.log data
      console.log "Again Now My Brain has: #{JSON.stringify(data)}"


      res.reply data
