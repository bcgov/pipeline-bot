

request = require('./request.coffee')


apikey = process.env.HUBOT_OCPAPIKEY
domain = process.env.HUBOT_OCPDOMAIN

# project = 'databcdc'
# buildConfig = 'bcdc-test-dev'
# deployConfig = 'pipeline-bot'

project = 'databcdc'
buildConfig = 'datapusher'
deployConfig = 'datapusher'

if apikey == undefined
    console.log 'APIKEY enviroment variable not defiend'

console.log "apikey: #{'*'.repeat(apikey.length)}"
api = new request.OCAPI(domain, apikey)


#DEBUG- Commenting out while working on deploy

# Try as I have to figure out how to make the build call
# simply buildSync()... It doesn't seem to be possible to 
# get the promise to wait / block the execution stack until
# the promise is complete, and THEN return a value.  Solution
# seems to be to just put the buildsync in a function
# as is demonstrated below.
buildDeploySync = () ->

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

    # todo: Thinking that could put another app specific test in here to 
    #       verify that the app can be pinged?


# call the build
console.log("project: #{project}")
buildDeploySync()

# should put this in a function with the build
