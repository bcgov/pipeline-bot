

module.exports = (robot) ->

   robot.respond /mission/i, (res) ->
     res.reply 'I am a CI/CD Pipeline Tool.  I will monitor and orchestrate deployments.'
     res.reply 'Feel free to check-in on me anytime by using "pipeline-bot status"'

   robot.respond /status/i, (res) ->
     res.reply 'Nothing to report. Currently under development at this time.'
