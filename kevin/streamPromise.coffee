request = require('request')
stream = require('stream')
oboe = require('oboe')
_ = require('lodash')

apikey = process.env.APIKEY
domain = process.env.DOMAIN
project = 'databcdc'

# TODO: need to add logic for incorrect api key

getDataOboe = (project) ->
    new Promise (resolve) ->

        monitorUrl = "https://#{domain}/apis/build.openshift.io/v1/watch/namespaces/#{project}/builds/bcdc-test-dev-1/"
        oboeReqestDef = {   
            url: monitorUrl,
            method: "GET",
            headers: {
                Accept: 'application/json, */*',
                Authorization : "Bearer #{apikey}"
            }
        }
        recordtype = undefined
        phase = undefined


        oboeRequest = oboe(oboeReqestDef)
            .node('*', (node, path) ->
                if ( path.length == 1) and path[0] == 'type'
                    cnt = cnt + 1
                    console.log "---------------record type: #{node}-----------------"
                    recordtype = node
                else if (path.length == 3) 
                    console.log "path--- #{JSON.stringify(path)}"
                    if _.isEqual(_.sortBy(path), _.sortBy(["object", "status", "phase"]))
                        phase = node
                        console.log "    phase: #{phase}"
                if recordtype == 'ADDED' and phase == 'New'
                    #if recordtype == 'MODIFIED' and phase == 'Complete'
                    console.log "returning data: #{recordtype} #{phase}"
                    resolve [recordtype, phase]
                    this.abort()
                cnt = cnt + 1
            )
            .fail( ( errorReport ) ->
                console.log "error caught here"
                console.log "status code: #{errorReport.statusCode}")
            .done( () ->
                console.log "done")
        #resolve oboeRequest
        
retVal = getDataOboe(project)
console.log "retval #{retVal} #{typeof retVal}"

retVal.then (data) ->
    # 
    console.log 'the return value: ' + data + " " + typeof data
    console.log JSON.stringify(data)

