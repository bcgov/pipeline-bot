request = require('request')
stream = require('stream')
oboe = require('oboe-promise')
oboe = require('oboe')
_ = require('lodash')

apikey = process.env.APIKEY
domain = process.env.DOMAIN
project = 'databcdc'

# TODO: need to add logic for incorrect api key

getDataOboe = (project) ->
    new Promise (resolve) ->

        monitorUrl = "https://#{domain}/apis/build.openshift.io/v1/watch/namespaces/#{project}/builds/"
        oboeReqestDef = {   
            url: monitorUrl,
            method: "GET",
            headers: {
                Accept: 'application/json, */*',
                Authorization : "Bearer #{apikey}"
            }
        }
        cnt = 0
        recordtype = undefined
        phase = undefined


        oboeRequest = oboe(oboeReqestDef)
            .node('*', (node, path) ->
                if ( path.length == 1) and path[0] == 'type'
                    cnt = cnt + 1
                    console.log "---------------record type: #{node}-----------------"
                    recordtype = node
                else if (path.length == 3) 
                    console.log "#{JSON.stringify(path)}"
                    if _.isEqual(path, ["object", "status", "phase"])
                        phase = node
                if recordtype == 'ADDED' and phase == 'Complete'
                    this.done()
                    this.abort()
                    console.log "returning data: #{recordtype} #{phase}"
                    resolve [recordtype, phase]
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

