
class OCAPI
    domain = null
    protocol = 'https'

    apiEndPoints = '/oapi/v1/'

    constructor : (domain, apikey=null) ->
        @domain = domain
        @protocol = protocol
        @apikey = apikey
        #console.log "domain is :"+@domain
        #console.log "protocol is: " + @protocol

    baseUrl : ->
        return "#{protocol}://#{@domain}"

    getAPIEndPoints : ->
        urldomain = this.baseUrl()
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj = {uri:urlString, json : true, method: 'GET',}
        console.log "urlString: -" +  urlString + '-'

        request = require('request-promise')
        json = ""
        return request reqObj
           .then (response) -> 
               console.log response.resources.length
               json = response
           .catch (err) -> 
               console.log '------- error called -------' + err.resources.length
               json = err
           
    startBuild : (ocProject, ocBuildConfigName )->
        request = require('request-promise')

        urldomain = this.baseUrl()

        initBuildPath = "/apis/build.openshift.io/v1/namespaces/#{ocProject}/buildconfigs/#{ocBuildConfigName}/instantiate"

        urlString = "#{urldomain}#{initBuildPath}"
        reqObj = {
            uri:urlString, 
            json : true, method: 'POST',
            body: {
                kind: "BuildRequest",
                apiVersion: "build.openshift.io/v1",
                metadata: {
                    name: "bcdc-test-dev",
                    creationTimestamp: null
                },
                triggeredBy: [
                    {
                        message: "Triggered with coffee"
                    }
                ],
                dockerStrategyOptions: {},
                sourceStrategyOptions: {}
            },
            headers: {
                Accept: 'application/json, */*'
            },
        }
        if this.apikey?
            reqObj.headers.Authorization =  "Bearer #{this.apikey}"
            console.log 'authorization is: ' + reqObj.headers.Authorization
        
        return request reqObj
           .then (response) -> 
               console.log response
               json = response
               console.log JSON.stringify(response, undefined, 2)
           .catch (err) -> 
               console.log '------- error called -------'
               console.log err
               json = err


        
# call the function that was created
#getAPIEndPoints()

apikey = process.env.API
domain = process.env.DOMAIN


api = new OCAPI(domain, apikey)
#retVal = api.getAPIEndPoints() # returns promise
#console.log "retVal: " + retVal


project = 'databcdc'
buildConfig = 'bcdc-test-dev'
retVal = api.startBuild(project, buildConfig)
console.log "retVal: " + retVal
