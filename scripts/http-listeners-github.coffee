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
#   example: curl -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" -d @$GITHUB_EVENT_PATH https://${{ secrets.BOT_URL }}/hubot/github/dev
#
#
# Author:
#   craigrigdon


mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN
devApiTestTemplate = process.env.HUBOT_DEV_APITEST_TEMPLATE
testApiTestTemplate = process.env.HUBOT_TEST_APITEST_TEMPLATE
pipelineMap = process.env.HUBOT_PIPELINE_MAP


request = require('./request.coffee')
api = new request.OCAPI(domain, apikey)
route = '/hubot/github/:envkey'

buildDeploySync = (project, buildConfig, deployConfig) ->

    console.log("project: #{project}")

    retVal = await api.buildSync(project, buildConfig) # returns promise
    # what you want to do with the build sync
    console.log('---complete---')
    console.log("#{JSON.stringify(retVal)}")
    console.log("#{typeof retVal}")

    console.log("----- running deploy now -----")
    deployStatus =  await api.deployLatest(project, buildConfig, deployConfig)
    console.log "DEPLY STATUS: #{deployStatus}"
    console.log JSON.stringify(deployStatus)
    await return deployStatus


module.exports = (robot) ->

  robot.router.post route, (req, res) ->

    console.log route
    env = req.params.envkey
    console.log env

    # -------------- STAGE Commit ------------
    stage = "Commit"
    status = "in progress"
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

    # From Payload and param define what env var we should pull from config map.
    buildConfig = null
    deployConfig = null
    project = null

    pipes = (JSON.parse(pipelineMap))
    console.log pipes
    for pipe in pipes.pipelines
      console.log "#{JSON.stringify(pipe.name)}"
      if pipe.repo == repoName
        console.log "Repo found in conifg map: #{JSON.stringify(pipe.repoName)}"

        switch env
          when "dev"
            console.log "define vars for dev"
            console.log "#{JSON.stringify(pipe.dev)}"
            buildConfig = pipe.dev.buildconfig
            deployConfig = pipe.dev.deployconfig
            project = pipe.dev.namespace

          when "test"
            console.log "define vars for test"
            console.log "#{JSON.stringify(pipe.test)}"
            buildConfig = pipe.test.buildconfig
            deployConfig = pipe.test.deployconfig
            project = pipe.test.namespace

          else
            console.log "Error Required env arguments dev|test|prod"
#             TODO: exit and message error to chatroom and log to brain


    # message
    mesg = "Commit [#{commitID}](#{commitURL}) by #{committer} for #{ref} at #{timestamp} on [#{repoName}](#{repoURL})"
    console.log mesg

    # add to brain
    robot.brain.set(repoName, {id: "", stage: stage, status: status, entry: [mesg]})

    # send message to chat
    robot.messageRoom mat_room, "#{mesg}"

    # -------------- STAGE Build/Deploy ------------
    # start build deploy watch
    stage = "build and deploy"

    # message
    mesg = " Starting Build and Deploy for #{buildConfig}"

    # send message to chat
    robot.messageRoom mat_room, mesg

    # update brain
    event = robot.brain.get(repoName)
    event.entry.push mesg
    event.stage = stage

    # call build/deploy watch
    resp = await buildDeploySync(project, buildConfig, deployConfig)

    console.log "your response is : #{JSON.stringify(resp)}"
    console.log resp.statuses

    deploydStatus = resp.statuses.deploy.status
    deployKind = resp.statuses.deploy.payload.kind
    deployName = resp.statuses.deploy.payload.metadata.name
    deployCreationTimestamp = resp.statuses.deploy.payload.metadata.creationTimestamp
    deployUID = resp.statuses.deploy.payload.metadata.uid

    # message
    mesg = "#{deployKind} #{deploydStatus} #{deployName} #{deployCreationTimestamp} #{deployUID} "
    console.log mesg

    # update brain
    event = robot.brain.get(repoName)
    event.entry.push mesg
    event.id = deployUID

    # send message to chat
    robot.messageRoom mat_room, "#{mesg}"

    #----------------STAGE TEST----------------------
    if deploydStatus == "success"
      stage = "Testing"
      env = "dev"  # hard code for testing only

      if env == 'dev'
         templateUrl = devApiTestTemplate
      else if env == 'test'
         templateUrl = testApiTestTemplate
      else
         templateUrl = ""
         console.log "failed to set templateURL"
         return
      #TODO: err check args and exit , let chat room know
      console.log env

      # get job template from repo
      robot.http(templateUrl)
        .header('Accept', 'application/json')
        .get() (err, httpres, body) ->

          # check for errs
          if err
            console.log "Encountered an error :( #{err}"
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

          #add env var with ID of deployment for tracking
          data =  {"name": "DEPLOY_UID","value": deployUID}
          console.log "#{JSON.stringify(data)}"
          console.log "add new data to job yaml"
          job.spec.template.spec.containers[0].env.push data
          console.log "#{JSON.stringify(job)}#"

          # send job to ocp api jobs endpoint
          robot.http("https://#{domain}/apis/batch/v1/namespaces/#{project}/jobs")
           .header('Accept', 'application/json')
           .header('Authorization', "Bearer #{apikey}")
           .post(JSON.stringify(job)) (err, httpRes, body2) ->
            # check for errs
            if err
              console.log "Encountered an error :( #{err}"
              return

            data = JSON.parse body2
            console.log "returning jobs response"
            console.log data

            # check for ocp returned status responses.
            if data.kind == "Status"
              status = data.status
              reason = data.message
              console.log "#{status} #{reason} "
              return

            #continue and message back succesful resp details
            kind = data.kind
            buildName = data.metadata.name
            namespace = data.metadata.namespace
            time = data.metadata.creationTimestamp

            mesg = "Starting #{kind} #{buildName} in #{namespace} at #{time}"
            console.log mesg

            # update brain
            event = robot.brain.get(repoName)
            event.entry.push mesg
            event.stage = stage

            # send message to chat
            robot.messageRoom mat_room, "#{mesg}"



    status = "Success"
    res.send status
