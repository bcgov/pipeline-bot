

request = require('./request.coffee')


apikey = process.env.APIKEY
domain = process.env.DOMAIN

console.log "apikey: #{'*'.repeat(apikey.length)}"

api = new request.OCAPI(domain, apikey)
#retVal = api.getAPIEndPoints() # returns promise

project = 'databcdc'
buildConfig = 'bcdc-test-dev'
api.getAPIEndPoints()

status = api.buildSync(project, buildConfig)
console.log("status: #{status}")
