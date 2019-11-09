

# experiment in how to watch the oc build request.



request = require('request-promise')
rq = require('request')
stream = require('stream')
_ = require('lodash')
oboe = require('oboe')


class OCAPI
    domain = null
    protocol = 'https'
    buildStatus = 'NOT STARTED'
    deployStatus = 'NOT STARTED'

    requestTimeoutSeconds = 300

    constructor : (domain, apikey=null) ->
        @domain = domain
        @protocol = protocol
        @apikey = apikey

    baseUrl : ->
        return "#{protocol}://#{@domain}"

    getAPIEndPoints : ->
        urldomain = this.baseUrl()
        apiEndPoints = '/oapi/v1/'
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj = {uri:urlString, json : true, method: 'GET',}
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
        console.log "url String: #{urlString}"

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

    watchBuildNP : (ocProject, buildData)->
        reqConfig = {
            method: 'GET',
            headers: {
                Accept: 'application/json, */*'
            },
        }

        # add the api key to the request descriptor
        if this.apikey?
            reqConfig.headers.Authorization =  "Bearer #{this.apikey}"
            console.log 'authorization is: ' + reqConfig.headers.Authorization
        urldomain = this.baseUrl()

        watchBuildUrl = "#{urldomain}/apis/build.openshift.io/v1/watch/namespaces/#{ocProject}/builds/#{buildData.metadata.name}"
        watchBuildUrl = watchBuildUrl + "?timeoutSeconds=#{requestTimeoutSeconds}"
        reqConfig.url = watchBuildUrl
        oboePromise = new Promise (resolve) ->
            recordtype = undefined
            phase = undefined
            oboeRequest = oboe(reqConfig)
                .node('*', (node, path) ->
                    if ( path.length == 1) and path[0] == 'type'
                        cnt = cnt + 1
                        recordtype = node
                    else if (path.length == 3) 
                        console.log "#{JSON.stringify(path)}"
                        if _.isEqual(path, ["object", "status", "phase"])
                            phase = node
                            console.log "phase: #{phase}"
                    #if recordtype == 'ADDED' and phase == 'New'
                    if recordtype == 'MODIFIED' and ( phase in ['Complete', 'Cancelled'])
                        console.log "returning data: #{recordtype} #{phase}"
                        this.abort()
                        resolve [recordtype, phase]
                        this.done()
                )
                .fail( ( errorReport ) ->
                    console.log "status code: #{errorReport.statusCode}")
                .done( () ->
                    console.log "done")

    startAndWatch : (ocProject, ocBuildConfigName) ->
        # another pattern to try:
        #  https://stackoverflow.com/questions/33599688/how-to-use-es8-async-await-with-streams
        buildPromise = await this.startBuild(ocProject, ocBuildConfigName)
        console.log("buildPromise #{buildPromise}, #{typeof buildPromise}")
        console.log("buildPromise #{JSON.stringify(buildPromise)}, #{typeof buildPromise}")
        watchBuildStatus = await this.watchBuildNP(ocProject, buildPromise)
        console.log "---watchBuild---: #{watchBuildStatus} #{typeof watchBuildStatus}"
        return watchBuildStatus

# call the function that was created
#getAPIEndPoints()

apikey = process.env.APIKEY
domain = process.env.DOMAIN
console.log "apikey: #{apikey}"

api = new OCAPI(domain, apikey)
#retVal = api.getAPIEndPoints() # returns promise

project = 'databcdc'
buildConfig = 'bcdc-test-dev'

status = api.startAndWatch(project, buildConfig)
console.log("status: #{status}")
