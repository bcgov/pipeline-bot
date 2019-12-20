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
#   hubot brain (<add>|<show>|<clear>)  - add test entry, show all keys and values, clear all keys
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
      commitID = "abcdefg"
      dev_deploy_uid = "12345ABC"
      test_deploy_uid = "123456ABC"
      deploy_status = "success"
      status = "pending"
      entry = "testEntry"
      env = "dev"
      user = "craigrigdon"
      repo = "test"
      branch = "dev"
      base = "master"
      repoFullName = "craigrigdon/test"

      switch arg
        when "add"
          console.log "adding"
#          robot.brain.set(key, {id: id, stage: stage, status: status, entry: [entry]})
#                # create entry in Brain
          robot.brain.set("#{repoFullName}": {
              commit: 12345678,
              status: null,
              pullSha: null,
              pullNumber: null,
              repoFullName: repoFullName,
              repo: repo,
              user: user,
              branch :branch,
              base: base,
              env: env,
              entry: [entry],
              stage: {
                dev: {
                  deploy_uid: dev_deploy_uid,
                  deploy_status: deploy_status,
                  test_status: null,
                  promote: false
                },
                test: {
                  deploy_uid: test_deploy_uid,
                  deploy_status: deploy_status,
                  test_status: null,
                  promote: false
                },
                prod: {
                  deploy_uid: test_deploy_uid,
                  deploy_status: deploy_status,
                  test_status: null,
                  promote: false
                }
              }
            }
          )
          data = robot.brain.data._private
          console.log data
          console.log "My Brain has: #{JSON.stringify(data)}"
          res.reply "#{JSON.stringify(data)}"
        when "update"
          console.log "udpate"
          event = robot.brain.get(key)
          eventStage = event.stage.dev

          console.log eventStage
          console.log "My Brain has: #{JSON.stringify(eventStage)}"
          res.reply "#{JSON.stringify(eventStage)}"
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
        when "all"
          console.log "show all namespaces in brain"
          data = robot.brain.data
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
