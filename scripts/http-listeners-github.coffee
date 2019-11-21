# Description:
#   http listener for github action payload
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
#   expects GITHUB_EVENT_PATH payload from github actions
#   example: curl -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" -d @$GITHUB_EVENT_PATH https://${{ secrets.BOT_URL }}/hubot/github
#
#
# Author:
#   craigrigdon

# get mattermost channel from env var passed to container on deployment
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE

request = require('./request.coffee')

api = new request.OCAPI(domain, apikey)

buildSync = (project, buildConfig) ->
    console.log("project: #{project}")
    retVal = await api.buildSync(project, buildConfig) # returns promise
    # what you want to do with the build sync
    console.log('---complete---')
    console.log("#{JSON.stringify(retVal)}")
    console.log("#{typeof retVal}")
    await return retVal

route = '/hubot/github'


module.exports = (robot) ->

  robot.router.post route, (req, res) ->

    console.log route

    # TODO: error check payload
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    console.log data
    commitID = data.head_commit.id
    committer = data.head_commit.committer.username
    timestamp = data.head_commit.timestamp
    commitURL = data.head_commit.url
    repoName = data.repository.full_name
    repoURL = data.repository.html_url
    ref = data.ref

    # message
    mesg = "Commit [#{commitID}](#{commitURL}) by #{committer} for #{ref} at #{timestamp} on [#{repoName}](#{repoURL})"
    console.log mesg

    # add to brain
    robot.brain.set(repoName, {mesg: mesg})

    # send message to chat
    robot.messageRoom mat_room, "#{mesg}"

    #start build and watch
    buildConfig = "pipeline-bot" # hard code for testing only
    project = "databcdc" # hard code for testing only
#    res.reply "Lets start building #{buildConfig}"
    resp = await buildSync(project, buildConfig)
    console.log "your response is : #{JSON.stringify(resp)}"

    console.log resp.statuses
    status = resp.statuses.build.status
    kind = resp.statuses.build.payload.kind
    name = resp.statuses.build.payload.metadata.name
    creationTimestamp = resp.statuses.build.payload.metadata.creationTimestamp
    commit = resp.statuses.build.payload.spec.revision.git.commit

    mesg = "Commit #{commit} #{status} #{kind} #{name} #{creationTimestamp}"
    console.log mesg

    # add to brain
    robot.brain.set(repoName, {mesg: mesg})
#    res.reply mesg

    # send message to chat
    robot.messageRoom mat_room, "#{mesg}"

    if status == "Complete"
      env = "dev"  # hard code for testing only
      project = "databcdc"  # hard code for testing only

      if env == 'dev'
         templateUrl = devApiTestTemplate
      else if env == 'test'
         templateUrl = testApiTestTemplate
      else
         templateUrl = ""
         console.log "failed to set templateURL"
#         res.reply "please provide enviro option dev/test"
         return
      #TODO: err check args and exit
      console.log env

      robot.http(templateUrl)
        .header('Accept', 'application/json')
        .get() (err, httpres, body) ->

          # check for errs
          if err
#            res.reply "Encountered an error :( #{err}"
            return

          fs = require('fs')
          yaml = require('js-yaml')

          data = yaml.load(body)
          jsonString = JSON.stringify(data)
          jsonParsed = JSON.parse(jsonString)
          # get job object from template
          # TODO: check if kind is of job type
          job = jsonParsed.objects[0]
          console.log job

          # send job to ocp api jobs endpoint
          robot.http("https://#{domain}/apis/batch/v1/namespaces/#{project}/jobs")
           .header('Accept', 'application/json')
           .header('Authorization', "Bearer #{apikey}")
           .post(JSON.stringify(job)) (err, httpRes, body2) ->
            # check for errs
            if err
#              res.reply "Encountered an error :( #{err}"
              return

            data = JSON.parse body2
            console.log "returning jobs response"
            console.log data

            # check for ocp returned status responses.
            if data.kind == "Status"
              status = data.status
              reason = data.message
#              res.reply "#{status} #{reason} "
              return

            #continue and message back succesful resp details
            kind = data.kind
            buildName = data.metadata.name
            namespace = data.metadata.namespace
            time = data.metadata.creationTimestamp

            mesg = "Starting #{kind} #{buildName} in #{namespace} at #{time}"
            console.log mesg

            # add to brain
            robot.brain.set(repoName, {mesg: mesg})

            # send message to chat
            robot.messageRoom mat_room, "#{mesg}"


    status = "Success"
    res.send status
