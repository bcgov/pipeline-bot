# Description:
#   Create Github Pull Requests with Hubot.
#
# Dependencies:
#   "githubot": "^1.0.1"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
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

module.exports = (robot) ->

  robot.on "github-pr", (obj) ->
    github = require('githubot')(robot)

    console.log "called github-pr"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    user = obj.event.user
    repo = obj.event.repo
    branch = obj.event.branch
    base = obj.base
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
          msg.send 'Error: failed to access repo.'
        when 422
          msg.send "Error: pull request has already been created or the branch does not exist."
        else
          msg.send 'Error: something is wrong with your request.'

    github.post "repos/#{user}/#{repo}/pulls", data, (pr) ->
      mesg = "Success! Pull request created for #{head}. #{pr.html_url}"

      console.log "Pull Request from github  : #{JSON.stringify(pr)}"
      console.log mesg
      msg.send mesg




