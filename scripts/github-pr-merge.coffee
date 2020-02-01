# Description:
#   Create Github Merge Pull Requests with Hubot.
#
# Dependencies:
#   "githubot": "^1.0.1"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_MATTERMOST_CHANNEL
#   HUBOT_CONFIG_PATH
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
matroom = process.env.HUBOT_MATTERMOST_CHANNEL
configPath = process.env.HUBOT_CONFIG_PATH

module.exports = (robot) ->

  robot.on "github-pr-merge", (obj) ->

    # expecting from obj
    # event    : event, #event object from brain
    # buildObj   : buildObj, #build object from config
    # deployObj  : deployObj, #deploy object from config
    # eventStage   : eventStage, #stage object from brain
    # envKey  : envKey, #env key

    github = require('githubot')(robot)

    console.log "called github-pr-merge"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    user = obj.event.event.user
    repo = obj.event.event.repo
    branch = obj.event.event.branch
    base = obj.event.event.base
    pullSha = obj.event.event.pullSha
    pullNumber = obj.event.event.pullNumber

    data = {
        commit_title: "Autobot Merg pull request Test Title",
        sha: pullSha,
        commit_message: "Autobot Merg pull request Test Message",
        merge_method: "merge"
    }
    console.log "data to pass to github  : #{JSON.stringify(data)}"

    # decide how we would like to hangle our github errors
    github.handleErrors (response) ->
      switch response.statusCode
        when 409
          robot.messageRoom matroom, "Error: merge conflict. #{response.message}"
        when 404
          robot.messageRoom matroom, "Error: failed to access repo. #{response.message}"
        when 422
          robot.messageRoom matroom, "Error: pull request has already been created or the branch does not exist. #{response.message}"
        else
          robot.messageRoom matroom, "Error: #{response.message}"

    # call github pr merge api
    #TODO: 404 on merge call..... must run test locally
#    /repos/:owner/:repo/pulls/:pull_number/merge
    github.put "repos/#{user}/#{repo}/pulls/#{pullNumber}/merge", data, (pr) ->
      mesg = "Success! Merged Pull request for #{branch}."

      console.log "Merged Pull Request from github  : #{JSON.stringify(pr)}"
      console.log mesg

      # update brain
      obj.event.event.entry.push mesg
      console.log "#{JSON.stringify(obj.event)}"

      # send message to chat
      robot.messageRoom matroom, "#{mesg}"

      # sent to build deploy test script
      robot.emit "build-deploy-stage", {
          build    : obj.buildObj, #build object from config file
          deploy   : obj.deployObj, #deploy object from config file
          repoFullName    : obj.event.event.repoFullName, # repo name from github payload
          eventStage : obj.eventStage, # stage object from memory to update
          envKey : obj.envKey, # environment key
      }




