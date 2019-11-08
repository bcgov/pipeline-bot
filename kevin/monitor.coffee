
request = require('request')
stream = require('stream')
JSONStream = require('JSONStream')


apikey = process.env.APIKEY
domain = process.env.DOMAIN
project = 'databcdc'

req = undefined

class LogStream extends stream.Writable

    jsonStr = ""
    

    _write: (chunk, enc, next) ->
        # dependent on json objects being concluded with \n
        # individual objects are parsed once a \n is found
        # otherwise the next adds to the string

        #console.log "---------------------"
        #console.log chunk + ' ' + typeof chunk
        jsonStr = jsonStr + chunk
        regex = /\n/
        result = regex.exec(chunk);

        if result
            #console.log jsonStr
            stringList = jsonStr.split /\n/ 
            #console.log stringList
            readyJson = stringList[0]
            #console.log readyJson

            jsonStr = stringList[1]
            console.log "leave json is: #{jsonStr}"

            dataObj = JSON.parse(readyJson)
            # now the logic
            console.log '----- DATA -----'
            console.log JSON.stringify(dataObj)
            # if dataObj.type == 'ADDED' and dataObj.object.status.startTimestamp == "2019-10-08T19:06:55Z"
            #     console.log("found what we are looking for closing stream")

            if ( dataObj.type == "MODIFIED" and 
                    dataObj.object.kind == 'Build' and
                    dataObj.status.phase == 'Complete')
                console.log "---------------------"
                console.log "BUILD COMPLETE"
                req.pause()
            else
                next()
        

getDataOboe = (project) ->
    monitorUrl = "https://#{domain}/apis/build.openshift.io/v1/watch/namespaces/#{project}/builds/bcdc-test-dev-75"
    oboeReqestDef = {   
        url: monitorUrl,
        method: "GET",
        headers: {
            Accept: 'application/json, */*',
            Authorization : "Bearer #{apikey}"
        }
    }
    #oboe(oboeReqestDef) ->
        
        



getData = (project) ->
    monitorUrl = "https://#{domain}/apis/build.openshift.io/v1/watch/namespaces/#{project}/builds/"
    console.log "url is: #{monitorUrl}"
    string = ''
    req = request({
        method: "GET",
        url: monitorUrl,
        json: true,
        forever: true, 
        headers: {
            Accept: 'application/json, */*',
            Authorization : "Bearer #{apikey}"
        }
    })

    req.pipe(new LogStream)

    # .on('error', (err))  -> 
    #    console.log err

    #.on('data', (buf) => string += buf.toString())
    #.on('end', () => console.log(string));

# anotherFunc = (stream) ->

#     console.log typeof stream
#     console.log JSON.stringify(stream)

console.log 'here'
getData(project)


