
exports.OCAPI = class OCAPI
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

    request = require('request-promise')

    startDeploy : (ocProject, ocDeployConfigName )->

        urldomain = this.baseUrl()
        initBuildPath = "/apis/apps.openshift.io/v1/namespaces/#{ocProject}/deploymentconfigs/#{ocDeployConfigName}/instantiate"

        urlString = "#{urldomain}#{initBuildPath}"
        reqObj = {
            uri:urlString,
            json : true, method: 'POST',
            body: {
                kind: "DeploymentRequest",
                apiVersion: "apps.openshift.io/v1",
                name: "pipeline-bot",
                latest: true,
                force: true
            },
            headers: {
                Accept: 'application/json, */*'
            },
        }
        if this.apikey?
            reqObj.headers.Authorization =  "Bearer #{this.apikey}"
            console.log 'authorization is: ' + reqObj.headers.Authorization

        request(reqObj)
           .then (response) ->
               console.log response
               json = response
               console.log JSON.stringify(response, undefined, 2)
               return response
           .catch (err) ->
               console.log '------- error called -------'
               console.log err
               json = err
