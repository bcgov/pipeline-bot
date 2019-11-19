

request = require('./request.coffee')


apikey = process.env.APIKEY
domain = process.env.DOMAIN

project = 'databcdc'
buildConfig = 'bcdc-test-dev'
deployConfig = 'pipeline-bot'

project = 'databcdc'
buildConfig = 'datapusher'
deployConfig = 'datapusher'

if apikey == undefined
    console.log 'APIKEY enviroment variable not defiend'

console.log "apikey: #{'*'.repeat(apikey.length)}"

api = new request.OCAPI(domain, apikey)

retVal = api.buildSync(project, buildConfig) # returns promise

#dep = api.deploy(project, deployConfig)
#dep.then (response) ->
#    console.log "response: #{JSON.stringify(response)}"
#    replicationController = "#{response.metadata.name}-#{response.status.latestVersion}"
#    api.deployWatch(project, replicationController)

# #api.getAPIEndPoints()
# isEqual = api.isLatestImageDeployed(project, buildConfig, deployConfig)
# console.log("isEqual: #{isEqual}")
# isEqual.then (response) ->
#     console.log("isEqual: #{response}")

# status = api.buildSync(project, buildConfig)
# console.log("status: #{status}")
