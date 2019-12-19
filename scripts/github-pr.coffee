# Description:
#   Create Github Pull Requests with Hubot.
#
# Dependencies:
#   "githubot": "^1.0.1"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_MATTERMOST_CHANNEL
#
# Commands:
#
#
# Notes:
#   You will need to create and set HUBOT_GITHUB_TOKEN.
#   The token will need to be made from a user that has access to repo(s)
#   you want hubot to interact with.
#
# Author:
#  craigrigdon

githubToken = process.env.HUBOT_GITHUB_TOKEN
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL

module.exports = (robot) ->

  robot.on "github-pr", (obj) ->
    github = require('githubot')(robot)

    console.log "called github-pr"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    user = obj.event.event.user
    repo = obj.event.event.repo
    branch = obj.event.event.branch
    base = obj.event.event.base
    pullSha = obj.event.event.pullSha
    pullNumber = obj.event.event.pullNumber

    pullRequestData = {
        title: "PR to merge #{branch} into #{base}",
        head: branch,
        base: base,
        body: "Autobot Pull request Test"
      }

    mergRequestData = {
        commit_title: "Autobot Merg pull request Test Title",
        sha: pullSha,
        commit_message: "Autobot Merg pull request Test Message"
        merge_method: "merge"
    }



    github.handleErrors (response) ->
      switch response.statusCode
        when 409
          robot.messageRoom mat_room, "Error: merge conflict. #{response.message}"
        when 404
          robot.messageRoom mat_room, "Error: failed to access repo. #{response.message}"
        when 422
          robot.messageRoom mat_room, "Error: pull request has already been created or the branch does not exist."
        else
          robot.messageRoom mat_room, "Error: #{response.message}"


    # Submit pull request or merg based on event

    if obj.event.event.pull != null
      console.log "data to pass to github  : #{JSON.stringify(pullRequestData)}"
      # call gitbub pr api
      github.post "repos/#{user}/#{repo}/pulls", pullRequestData, (pr) ->
        mesg = "Success! Pull request created for #{branch}. #{pr.html_url}"

        console.log "Pull Request from github  : #{JSON.stringify(pr)}"
        console.log mesg

        robot.messageRoom mat_room, "#{mesg}"

        # update brain

        obj.event.event.entry.push mesg
        obj.event.event.pullSha = pr.head.sha
        obj.event.event.pullNumber = pr.number
    else
      console.log "data to pass to github  : #{JSON.stringify(mergRequestData)}"

      github.post "repos/#{user}/#{repo}/pulls/#{pullNumber}/merges", mergRequestData, (pr) ->
        mesg = "Success! Pull request Merged for #{branch}. #{pr.html_url}"

        console.log "Pull Request from github  : #{JSON.stringify(pr)}"
        console.log mesg

        robot.messageRoom mat_room, "#{mesg}"


    # start build and deploy in next stage
    env = obj.event.event.env
    envKey = null #reset envKey
    switch env
      when "dev"
        mesg =  "Promoting to TEST Environment"
        robot.messageRoom mat_room, "#{mesg}"
        console.log mesg
        buildObj = obj.event.event.test.build
        deployObj = obj.event.event.test.deploy
        eventStage = obj.event.event.stage.test
        envKey = "test"

      when "test"
        mesg =  "Promoting to PROD Environment"
        robot.messageRoom mat_room, "#{mesg}"
        console.log mesg
        buildObj = obj.event.event.prod.build
        deployObj = obj.event.event.prod.deploy
        eventStage = obj.event.event.prod.test
        envKey = "prod"

      else
        mesg = "Promotion Error Required env arguments dev|test"
        console.log mesg
        robot.messageRoom mat_room, "#{mesg}"

    # update brain
    obj.event.event.entry.push mesg
    console.log "#{JSON.stringify(event)}"
    obj.event.event.env = envKey #update with new env key

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




