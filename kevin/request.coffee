
request = require('request-promise')
rq = require('request')


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
        
        request reqObj
           .then (response) -> 
               console.log response
               json = response
               console.log JSON.stringify(response, undefined, 2)
               return response
           .catch (err) -> 
               console.log '------- error called -------'
               console.log err
               json = err

    watchBuild : (ocProject, buildPromise)->
        reqObj = {
            json : true,
            method: 'GET',
            headers: {
                Accept: 'application/json, */*'
            },
        }

        # add the api key to the request descriptor
        if this.apikey?
            reqObj.headers.Authorization =  "Bearer #{this.apikey}"
            console.log 'authorization is: ' + reqObj.headers.Authorization
        urldomain = this.baseUrl()

        new Promise((resolve, reject) => {
            request.head(url, function(){
            request(url).pipe(fs.createWriteStream(pathName))
                .on('close', () => resolve(pathName))
                .on('error', error =>  reject(error))
            });
        })



        buildPromise.then (response) ->
            watchBuildUrl = "#{urldomain}/apis/build.openshift.io/v1/watch/namespaces/#{ocProject}/builds/#{response.metadata.name}"
            console.log "watch url is: " + watchBuildUrl
            reqObj.uri = watchBuildUrl
            

            # now call another request to watch
            return request reqObj

    monitorBuild : () ->
        # pipe example
        # https://stackoverflow.com/questions/51090164/wrapping-node-js-request-into-promise-and-piping/51090372
        reqObj = {
            json : true,
            method: 'GET',
            headers: {
                Accept: 'application/json, */*'
            }
        }



        
# call the function that was created
#getAPIEndPoints()

apikey = process.env.APIKEY
domain = process.env.DOMAIN
console.log "apikey: #{apikey}"

api = new OCAPI(domain, apikey)
#retVal = api.getAPIEndPoints() # returns promise
#console.log "retVal: " + retVal


project = 'databcdc'
buildConfig = 'bcdc-test-dev'
buildInitPromise = api.startBuild(project, buildConfig)
console.log "retVal: " + retVal


watchPromise = api.watchBuild(project, buildInitPromise)
api.monitorBuild(project, retVal)
