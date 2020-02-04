# Description:
#   Create Github Pull Requests with Hubot.
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

  robot.on "github-pr-open", (obj) ->

    # expecting from obj
    # event    : event, #event object from brain
    # buildObj   : buildObj, #build object from config
    # deployObj  : deployObj, #deploy object from config
    # eventStage   : eventStage, #stage object from brain
    # envKey  : envKey, #env key

    try
      github = require('githubot')(robot)

      console.log "called github-pr"
      console.log "object passed is  : #{JSON.stringify(obj)}"

      user = obj.event.user
      repo = obj.event.repo
      branch = obj.event.branch
      base = obj.event.base

      data = {
          title: "PR to merge #{branch} into #{base}",
          head: branch,
          base: base,
          body: "Autobot Pull Request Test"
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
      github.post "repos/#{user}/#{repo}/pulls", data, (pr) ->
        mesg = "Please Review #{pr.number} at #{pr.html_url} to continue pipeline."

        console.log "Pull Request from github  : #{JSON.stringify(pr)}"
        console.log mesg

        # update brain
        obj.event.entry.push mesg
        obj.event.pullSha = pr.head.sha
        obj.event.pullNumber = pr.number

        # send message to chat
        robot.messageRoom matroom, "#{mesg}"
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matroom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"

