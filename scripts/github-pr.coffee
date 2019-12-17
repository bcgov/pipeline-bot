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
    body = "Autobot Pull request Test"

    data = {
        title: "PR to merge #{branch} into #{base}",
        head: branch,
        base: base,
        body: body
      }
    console.log "data to pass to github  : #{JSON.stringify(data)}"

    github.handleErrors (response) ->
      switch response.statusCode
        when 404
          robot.messageRoom mat_room, 'Error: failed to access repo.'
        when 422
          robot.messageRoom mat_room, "Error: pull request has already been created or the branch does not exist."
        else
          robot.messageRoom mat_room, 'Error: something is wrong with your pull request.'

    github.post "repos/#{user}/#{repo}/pulls", data, (pr) ->
      mesg = "Success! Pull request created for #{branch}. #{pr.html_url}"

      console.log "Pull Request from github  : #{JSON.stringify(pr)}"
      console.log mesg
      robot.messageRoom mat_room, "#{mesg}"





