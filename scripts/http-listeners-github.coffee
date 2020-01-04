# Description:
#   http listener for github action payload
#
# Dependencies:
#
# Configuration:
#   HUBOT_MATTERMOST_CHANNEL
#
# Commands:
#
# Notes:
#   expects GITHUB_EVENT_PATH payload from github actions
#   param to signal which environment
#   example with param: curl -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" -d @$GITHUB_EVENT_PATH https://${{ secrets.BOT_URL }}/hubot/github/dev
#
# Author:
#   craigrigdon

matRoom = process.env.HUBOT_MATTERMOST_CHANNEL
configPath = process.env.HUBOT_CONFIG_PATH
route = '/hubot/github/:envkey'

#---------------Supporting Functions-------------------

getTimeStamp = ->
  date = new Date()
  timeStamp = date.getFullYear() + "/" + (date.getMonth() + 1) + "/" + date.getDate() + " " + date.getHours() + ":" +  date.getMinutes() + ":" + date.getSeconds()
  RE_findSingleDigits = /\b(\d)\b/g
  # Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )

#----------------Robot-------------------------------

module.exports = (robot) ->

  robot.router.post route, (req, res) ->
    console.log route
    # param
    envKey = req.params.envkey ? null
    console.log envKey

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    # check payload and param exist then send status back to source.
    if envKey == null || data == null
      status = "Expecting <path/(dev|test|prod)> with github event payload"
      console.log status
    else
      status = "Success"
      console.log status

    # check and continue
    if status == "Success"

      # define var from gitHub payload
      commitID = data.head_commit.id
      repoFullName = data.repository.full_name
      repoURL = data.repository.html_url
      repo = data.repository.name
      user = data.repository.owner.name
      base = data.repository.master_branch
      ref = data.ref
      branch = ref.split("/").pop()

      console.log "Checking #{commitID} on #{branch} for #{repoFullName} "


      #TODO check if pipeline exist if not create one.  currently set to create new
      check = null # set to null for testing
      if check == null

        # create entry in Brain
        robot.brain.set("#{repoFullName}": {
          commit: commitID,
          status: null,
          pullSha: null,
          pullNumber: null,
          repoFullName: repoFullName,
          repo: repo,
          user: user,
          branch : branch,
          base: base,
          env: envKey,
          entry: [],
          stage: {
            dev: {deploy_uid: null, deploy_status: null, test_status: null, promote: false},
            test: {deploy_uid: null, deploy_status: null, test_status: null, promote: false},
            prod: {deploy_uid: null, deploy_status: null, test_status: null, promote: false}
            }
          })

        event = robot.brain.get(repoFullName)
        console.log "Hubot Brain Has: #{JSON.stringify(event)}"

        # get config file from repo for pipeline mappings
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
           exhasted = false

           # check if repo is in config file
           results = pipes.pipelines.where repo: "#{repoFullName}"
           console.log results
           # process first result only
           pipe = results[0]

           if pipe?
            console.log "Repo found in conifg map: #{JSON.stringify(pipe.repo)}"

            #get event from brain
            event = robot.brain.get(repoFullName)

            switch envKey
              when "dev"
                console.log "define vars for dev"
                console.log "#{JSON.stringify(pipe.dev)}"
                buildObj = pipe.dev.build
                deployObj = pipe.dev.deploy
                envObj = pipe.dev # may use this later
                # get Stage object from brain
                eventStage = event.stage.dev

              when "test"
                console.log "define vars for test"
                console.log "#{JSON.stringify(pipe.test)}"
                buildObj = pipe.test.build
                deployObj = pipe.test.deploy
                envObj = pipe.test # may use this later
                # get Stage object from brain
                eventStage = event.stage.test

              else
                mesg = "Pipeline has been exhasted"
                console.log mesg
                exhasted = true


           console.log "#{JSON.stringify(buildObj)}"
           console.log "#{JSON.stringify(deployObj)}"
           console.log "#{JSON.stringify(eventStage)}"

           if exhasted == false

             # message
             mesg = "Recieved Github Event [#{commitID}] on [#{repoFullName}](#{repoURL})"
             console.log mesg

             # update brain
             event = robot.brain.get(repoFullName)
             event.entry.push mesg
             console.log "#{JSON.stringify(event)}"
             event.status = 'pending'

             # send message to chat
             robot.messageRoom matRoom, "#{mesg}"

             # sent to build deploy test script
             robot.emit "build-deploy-stage", {
                 build    : buildObj, #build object from config file
                 deploy   : deployObj, #deploy object from config file
                 repoFullName    : repoFullName # repo name from github payload
                 eventStage : eventStage # stage object from memory to update
                 envKey : envKey # enviromnet key
             }

             # send source status
             res.send status

           else
             mesg = "Pipeline has been exhasted for #{repoFullName}"
             console.log mesg

             # message room
             robot.messageRoom matRoom, "#{mesg}"

             # update brain
             event = robot.brain.get(repoFullName)
             event.entry.push mesg
             console.log "#{JSON.stringify(event)}"
             event.status = 'completed'

      else
        #TODO: update and enable logic
        if event.status == "pending"
          # Stop pipeline
          mesg = "Pipeline for #{repoFullName} is in Progress, Hubot will Not Start new Pipeline"
          console.log mesg

          # send mesg to chat room
          robot.messageRoom matRoom, "#{mesg}"

          #update brain
          event.status.push "failed"

          # send status back to source with results
          status = mesg
          res.send status

    else
      # source failed to pass required param and payload
      mesg = "Hubot will Not Start new Pipeline Source Failed to pass requred param and payload"
      console.log mesg

      # send mesg to chat room
      robot.messageRoom matRoom, "#{mesg}"

      # send status back to source with results
      status = mesg
      res.send status

