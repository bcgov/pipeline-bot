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
#   example: curl -X POST -H "Content-Type: application/json" -H "apikey: <key-if-required>" -d GITHUB_EVENT_PATH https://<bot-url/hubot/github
#
#
# Author:
#   craigrigdon

# get mattermost channel from env var passed to container on deployment
mat_room = process.env.HUBOT_MATTERMOST_CHANNEL
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

    # build message
    mesg = "Commit [#{commitID}](#{commitURL}) by #{committer} for #{ref} at #{timestamp} on [#{repoName}](#{repoURL})"
    console.log mesg

    # add to brain
    robot.brain.set(repoName, {mesg: mesg, timestamp: timestamp})

    # send message
    robot.messageRoom mat_room, "#{mesg}"

    # TODO: error check and return status
    status = "Success"
    res.send status
