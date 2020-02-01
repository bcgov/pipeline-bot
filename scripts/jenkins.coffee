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

matroom = process.env.HUBOT_MATTERMOST_CHANNEL

module.exports = (robot) ->

  robot.on "jenkins-job", (obj) ->
    # expecting from obj
    # job      : buildObj.jenkinsjob, # jenkins job name
    # build    : buildObj, #build object from config file
    # deploy   : deployObj, #deploy object from config file
    # repoFullName    : obj.event.repoFullName #repo name from github payload
    # eventStage : eventStage #stage object from memory to update
    # envKey : envKey #environment key

    console.log "Called jenkins script"
    console.log "object passed is  : #{JSON.stringify(obj)}"

    # message
    mesg = "Jenkins Build and Deploy for #{obj.repoFullName} in  #{obj.envKey}. Job #{obj.job}"

    try
      # update brain
      event = robot.brain.get(obj.repoFullName)
      event.entry.push mesg
      obj.eventStage.deploy_status = "pending"
    catch err
      console.log err
    finally
    # send message to chat
    robot.messageRoom matroom, mesg

    #build request
    url = process.env.HUBOT_JENKINS_URL
    command = "build"
    path = "#{url}/#{obj.job}/#{command}"
    console.log path
    req = robot.http(path)

    try
      if process.env.HUBOT_JENKINS_AUTH
        auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
        req.headers Authorization: "Basic #{auth}"

      req.header('Content-Length', 0)
      req.post() (err, res, body) ->
          if err
            mesg = "Jenkins says: #{err}"
          else if 200 <= res.statusCode < 400
            mesg = "(#{res.statusCode}) Build started for #{url}#{obj.job}"
          else if 400 == res.statusCode
            jenkinsBuild(msg, true)
          else if 404 == res.statusCode
            mesg = "Build not found, double check that it exists."
          else
            mesg = "Jenkins says: Status #{res.statusCode} #{body}"

          console.log mesg

          try
            # update brain
            event.entry.push mesg
            obj.eventStage.jenkins_job = obj.job
            obj.eventStage.deploy_status = "pending"
            obj.eventStage.deploy_uid = obj.job
          catch err
            console.log err
          finally
          # send message to chat
          robot.messageRoom matroom, mesg
    catch err
      console.log err
       # send message to chat
      robot.messageRoom matroom, "Error: See Pipeline-bot Logs in OCP. Have a Great Day!"
