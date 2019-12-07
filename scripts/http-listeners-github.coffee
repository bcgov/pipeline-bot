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
configPath = process.env.HUBOT_CONFIG_PATH ? 'https://raw.githubusercontent.com/bcgov/pipeline-bot/EventEmitter/config/config.json' #testing only
route = '/hubot/github/:envkey'
pipelineMap = process.env.HUBOT_PIPELINE_MAP

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

    #define stage and status
    stage = "init"
    status = "in progress"

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data

    # check payload and param exist then send status back to source.
    if envKey == null || data == null
      status = "Success"
    else
      status = "Expecting <path/(dev|test)> with json payload"
    # send source status
    res.send status

    # check and continue
    if status = "Success"

      # define var from gitHub payload
      commitID = data.head_commit.id
      committer = data.head_commit.committer.username
      timestamp = data.head_commit.timestamp
      commitURL = data.head_commit.url
      repoName = data.repository.full_name
      repoURL = data.repository.html_url
      ref = data.ref

      # get config file from repo for pipeline mappings
      robot.http(configPath)
       .header('Accept', 'application/json')
       .get() (err, httpres, body) ->

       # check for errs
         if err
           res.reply "Encountered an error fetching config file :( #{err}"
           return

         config = if req.body.payload? then JSON.parse req.body.payload else req.body
         console.log config

         buildObj = null
         deployObj = null

         for pipe in config.pipelines
           console.log "#{JSON.stringify(pipe.name)}"
           if pipe.repo == repoName
             console.log "Repo found in conifg map: #{JSON.stringify(pipe.repoName)}"

             switch env
               when "dev"
                 console.log "define vars for dev"
                 console.log "#{JSON.stringify(pipe.dev)}"
                 buildObj = pipe.dev.build
                 deployObj = pipe.dev.deploy

               when "test"
                 console.log "define vars for test"
                 console.log "#{JSON.stringify(pipe.test)}"
                 buildObj = pipe.test.build
                 deployObj = pipe.test.deploy

               else
                 console.log "Error Required env arguments dev|test|prod"
                 # TODO: exit and message error to chatroom and log to brain


         # message
         mesg = "Commit [#{commitID}](#{commitURL}) by #{committer} for #{ref} at #{timestamp} on [#{repoName}](#{repoURL})"
         console.log mesg

         # add to brain
         robot.brain.set(repoName, {id: "", stage: stage, status: status, entry: [mesg]})

         # send message to chat
         robot.messageRoom matRoom, "#{mesg}"

         robot.emit "GitHubEvent", {
             buildObj    : buildObj, #build object from config file
             deployObj   : deployObj, #deploy object from config file
             repoName    : repoName # repo name from github payload
         }


