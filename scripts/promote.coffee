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
configPath = process.env.HUBOT_CONFIG_PATH

#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.on "promote", (obj) ->
    # expecting from obj
    # event : event # event object from brain

    console.log "promote has been called"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    env = obj.event.env
    stage = obj.event.stage[env]

    console.log "object to promote : #{JSON.stringify(stage)}"
    if stage.deploy_status == "success" && stage.test_status == "Passed" && stage.promote == false

      mesg = "Promoting #{obj.event.repoFullName}"
      console.log mesg

      # message room
      robot.messageRoom mat_room, "#{mesg}"

      #update brain
      entry = mesg
      obj.event.entry.push entry
      stage.promote = true

      # check if prod, if so stop and complete else continue on as planned
      if env != "prod"
        robot.http(configPath)
          .header('Accept', 'application/json')
          .get() (err, httpres, body2) ->

            # check for errs
            if err
              console.log "Encountered an error fetching config file :( #{err}"
              body2 =  process.env.HUBOT_PIPELINE_MAP ? null  # hardcode for local testing only to be removed

            pipes = JSON.parse(body2)
            console.log pipes

            buildObj = null
            deployObj = null
            eventStage = null

            for pipe in pipes.pipelines
              console.log "#{JSON.stringify(pipe.name)}"

              if pipe.repo == obj.event.repoFullName
                console.log "Repo found in conifg map: #{JSON.stringify(pipe.repo)}"

                # start build and deploy in next stage
                env = obj.event.env
                envKey = null #reset envKey
                switch env
                  when "dev"
                    mesg =  "Promoting to TEST Environment"
                    console.log mesg
                    buildObj = pipe.test.build
                    deployObj = pipe.test.deploy
                    eventStage = obj.event.stage.test
                    envKey = "test"

                  when "test"
                    mesg =  "Promoting to PROD Environment"
                    console.log mesg
                    buildObj = pipe.prod.build
                    deployObj = pipe.prod.deploy
                    eventStage = obj.event.stage.prod
                    envKey = "prod"

                  else
                    mesg = "Promotion Error Required env arguments dev|test"
                    console.log mesg

                # check if event has pull request pending
                if obj.event.pullNumber == null
                  # send to create pull request
                  robot.emit "github-pr", {
                    event    : obj, #event object from brain
                    buildObj   : buildObj, #build object from config
                    deployObj  : deployObj, #deploy object from config
                    eventStage   : eventStage, #stage object from brain
                    envKey  : envKey, #env key
                  }
                else
                  # merge pull request
                  robot.emit "github-pr-merge", {
                    event    : obj, #event object from brain
                    buildObj   : buildObj, #build object from config
                    deployObj  : deployObj, #deploy object from config
                    eventStage   : eventStage, #stage object from brain
                    envKey  : envKey, #env key
                  }

                # message room
                robot.messageRoom mat_room, "#{mesg}"

                #update brain
                entry = mesg
                obj.event.entry.push entry
                stage.promote  = true
                obj.event.env = envKey

      else
        mesg = "Completed Pipeline #{obj.event.repoFullName}"
        console.log mesg

        # message room
        robot.messageRoom mat_room, "#{mesg}"

        #update brain
        obj.event.status = "completed"
        obj.event.entry.push entry
    else
      mesg = "Do Not promote #{obj.event.repoFullName}"
      console.log mesg

      # message room
      robot.messageRoom mat_room, "#{mesg}"

      #update brain
      entry = mesg
      obj.event.entry.push entry
      stage.promote  = false
      obj.event.status = "failed"

