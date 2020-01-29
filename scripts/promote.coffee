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


Array::where = (query) ->
    return [] if typeof query isnt "object"
    hit = Object.keys(query).length
    @filter (item) ->
        match = 0
        for key, val of query
            match += 1 if item[key] is val
        if match is hit then true else false


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
    # logic to promote or not to promote
    if stage.deploy_status == "success" && stage.test_status == "Passed" && stage.promote == false

      console.log mesg

      # check if prod, if so stop and complete else continue on as planned
      if env != "prod"
        robot.http(configPath)
          .header('Accept', 'application/json')
          .get() (err, httpres, body2) ->

            # check for errs
            if err
              console.log "Encountered an error fetching config file :( #{err}"
              body2 =  process.env.HUBOT_PIPELINE_MAP ? null  # env var for local testing only to be removed

            pipes = JSON.parse(body2)
            console.log pipes

            buildObj = null
            deployObj = null
            eventStage = null
            exhausted = false

            # check if repo is in config file
            results = pipes.pipelines.where repo: "#{obj.event.repoFullName}"
            console.log results
            #process first result only
            pipe = results[0]

            if pipe?
              console.log "Repo found in conifg map: #{JSON.stringify(pipe.repo)}"

              # setup vars for build and deploy
              env = obj.event.env
              envKey = null # reset envKey
              switch env
                when "dev"
                  mesg =  "Promoting to TEST Environment"
                  console.log mesg
                  buildObj = pipe.test.build
                  deployObj = pipe.test.deploy
                  eventStage = obj.event.stage.test
                  envKey = "test"

                when "test"
                  mesg =  "Promoting to STAGE Environment"
                  console.log mesg
                  buildObj = pipe.stage.build
                  deployObj = pipe.stage.deploy
                  eventStage = obj.event.stage.stage
                  envKey = "stage"

                when "stage"
                  mesg =  "Promoting to PROD Environment"
                  console.log mesg
                  buildObj = pipe.prod.build
                  deployObj = pipe.prod.deploy
                  eventStage = obj.event.stage.prod
                  envKey = "prod"

                else
                  mesg = "Pipeline has been exhasted"
                  console.log mesg
                  exhausted = true

              # build and deploy if not exhasted
              if exhausted == false

                #Checking if Jenkins Job else send to OCP to build and deploy
                if buildObj.jenkinsjob
                  # sent to jenkins script
                  robot.emit "jenkins-job", {
                      job      : buildObj.jenkinsjob, # jenkins job name
                      build    : buildObj, #build object from config file
                      deploy   : deployObj, #deploy object from config file
                      repoFullName    : obj.event.repoFullName #repo name from github payload
                      eventStage : eventStage #stage object from memory to update
                      envKey : envKey #environment key
                  }
                else
                  # sent to build deploy script for OCP
                  robot.emit "build-deploy-stage", {
                      build    : buildObj, #build object from config file
                      deploy   : deployObj, #deploy object from config file
                      repoFullName    : obj.event.repoFullName #repo name from github payload
                      eventStage : eventStage #stage object from memory to update
                      envKey : envKey #environment key
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
              mesg = "Repo Not found in conifg map: #{obj.event.repoFullName}"
              console.log mesg

              # message room
              robot.messageRoom mat_room, "#{mesg}"

              #update brain
              entry = mesg
              obj.event.entry.push entry
              stage.promote  = false
              obj.event.status = "failed"

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

