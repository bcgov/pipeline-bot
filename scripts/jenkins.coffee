 # Description:
#   Interact with your Jenkins
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_AUTH
#
#   Auth should be in the "user:password" format.
#
# Commands:
#
# Author:
#   crigdon


module.exports = (robot) ->

  robot.on "jenkins-build", (obj) ->

    # expecting from obj
    # job    : job, #jenkins job name

    url = process.env.HUBOT_JENKINS_URL

    command = "build"
    path = "#{url}/job/#{obj.job}/#{command}"
    console.log path

    req = robot.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
        if err
          console.log "Jenkins says: #{err}"
        else if 200 <= res.statusCode < 400 # Or, not an error code.
          console.log "(#{res.statusCode}) Build started for #{obj.job} #{url}/job/#{obj.job}"
        else if 400 == res.statusCode
          jenkinsBuild(msg, true)
        else if 404 == res.statusCode
          console.log "Build not found, double check that it exists."
        else
          console.log "Jenkins says: Status #{res.statusCode} #{body}"

