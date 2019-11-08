
request = require('request-promise')
rq = require('request')
stream = require('stream')

class OCAPI
    domain = null
    protocol = 'https'
    buildStatus = 'NOT STARTED'
    deployStatus = 'NOT STARTED'

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

    watchBuild : (ocProject, buildPromise)->
        reqConfig = {
            json : true,
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

        buildPromise.then (response) ->
            console.log JSON.stringify(response)
            watchBuildUrl = "#{urldomain}/apis/build.openshift.io/v1/watch/namespaces/#{ocProject}/builds/#{response.metadata.name}"
            console.log "watch url is: " + watchBuildUrl
            reqConfig.uri = watchBuildUrl
            reqObj = rq(reqConfig)
            return reqObj

    startAndWatch : (ocProject, ocBuildConfigName) ->
        # another pattern to try:
        #  https://stackoverflow.com/questions/33599688/how-to-use-es8-async-await-with-streams
        buildPromise = this.startBuild(ocProject, ocBuildConfigName)
        await watchBuild = this.watchBuild(ocProject, buildPromise)
        watcher = this.monitorBuild(watchBuild)
        console.log "watcher: #{watcher.status}"
        return watcher.status

    monitorBuild : (watchPromise) ->
        # https://2ality.com/2018/04/async-iter-nodejs.html
        watcher = undefined
        await watchPromise.then (request) ->
            watcher = new WatchBuildTillComplete(request)
            await myCoolPromise = new Promise (resolve, reject) ->
                # do a thing
                request.pipe(watcher).on('abort', () ->
                    console.log "end is found")
                success = true
                if success
                    console.log("success on thepipe")
                    resolve watcher
                else
                    console.log("trapped error")
                    reject Error 'it broke'
            return watcher
        

        # watchPromise.then(request) ->
        #     watcher = new WatchBuildTillComplete(request)
        #     reqObj.pipe(watcher)
        #     return new Promise (resolve, reject) =>
        #         watcher.on('finish', resolve)
        #         watcher.on('abort', resolve)
        #         watcher.on('error', reject)
        #     .then(() => result.join(''))

        

class WatchBuildTillComplete extends stream.Writable
    # strings recieved from the feed are appended here until 
    # a complete json object can be parsed
    # 
    # useful links in sorting this out:
    #  https://developer.mozilla.org/en-US/docs/Web/API/Streams_API/Using_readable_streams
    #  http://oboejs.com/api - (see BYO Stream)
    #  https://stackoverflow.com/questions/9829811/how-can-i-parse-the-first-json-object-on-a-stream-in-js
    #  https://www.freecodecamp.org/news/node-js-streams-everything-you-need-to-know-c9141306be93/
    #  https://jeroenpelgrims.com/node-streams-in-coffeescript/ - COFFEESCRIPT STREAMS
    #  https://www.codota.com/code/javascript/functions/request/Request/pipe
    #  

    constructor : (reqObj) ->
        super()
        @req = reqObj
        @status = 'PENDING'
        console.log "reqObj #{@req}  #{typeof @req}"

    jsonStr = ""

    _write: (chunk, enc, next) ->
        # dependent on json objects being concluded with \n
        # individual objects are parsed once a \n is found
        # otherwise the next adds to the string

        jsonStr = jsonStr + chunk
        regex = /\n/
        result = regex.exec(chunk);

        if result
            stringList = jsonStr.split /\n/ 
            readyJson = stringList[0]

            jsonStr = stringList[1]

            dataObj = JSON.parse(readyJson)
            # now the logic
            console.log '----- DATA -----'
            if ( dataObj.type == "MODIFIED" and 
                    dataObj.object.kind == 'Build' and
                    dataObj.object.status.phase == 'Complete')
                @status = "COMPLETE"
                @req.abort()
            else
                console.log "\nGetting next chunk of data from the stream..."
                next()

        

# call the function that was created
#getAPIEndPoints()

apikey = process.env.APIKEY
domain = process.env.DOMAIN
console.log "apikey: #{apikey}"

api = new OCAPI(domain, apikey)
#retVal = api.getAPIEndPoints() # returns promise

project = 'databcdc'
buildConfig = 'bcdc-test-dev'

#buildInitPromise = api.startBuild(project, buildConfig)
# watchPromise = api.watchBuild(project, buildInitPromise)
# monitorPromise = api.monitorBuild(watchPromise)
# monitorPromise.then (results)->
#     console.log("Build results: #{results}")

status = api.startAndWatch(project, buildConfig)
console.log("status: #{status}")




