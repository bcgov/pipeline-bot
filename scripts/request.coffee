###*
#  @fileOverview Wrapper methods to openshift to be used in a hubot
#                pipeline.
#
#  @author       Kevin Netherton
#
#  @requires     NPM:request-promise
#  @requires     NPM:lodash
#  @requires     NPM:oboe
###


request = require('request-promise')
_ = require('lodash')
oboe = require('oboe')


class exports.OCAPI
    domain = null
    protocol = 'https'
    buildStatus = 'NOT STARTED'
    deployStatus = 'NOT STARTED'

    requestTimeoutSeconds = 300

    constructor : (domain, apikey=null) ->
        @domain = domain
        @protocol = protocol
        @apikey = apikey
        @statuses = new OCStatus()

    ###*
    # Joins the protocol 'https' with the domain to form the root 
    # of the url
    #
    #  @returns {url} the domain and protocol joined together.
    ###
    baseUrl : ->
        return "#{protocol}://#{@domain}"

    ###*
    # returns a basic request object that other methods can then add 
    # to, always required will the addition of the uri 
    # 
    # @returns {reqObj} a basic request object with some commonly used
    #                   parameters
    ###
    getCoreRequest :  ->
        reqObj = {
                    json : true,
                    method: 'GET',
                    headers: {
                        Accept: 'application/json, */*'
                    }
        }
        if this.apikey?
            reqObj.headers.Authorization =  "Bearer #{this.apikey}"
        return reqObj

    ###*
    # queries openshift to get a json struct that describes the end 
    # points supported by the openshift instance
    # 
    # @returns {reqObj} a promise that will return the api end points 
    #                   available for the openshift api.
    ###
    getAPIEndPoints : ->
        urldomain = this.baseUrl()
        apiEndPoints = '/oapi/v1/'
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj = this.getCoreRequest()
        reqObj.uri = urlString
        json = ""
        return request reqObj
           .then (response) -> 
               console.log response.resources.length
               json = response
           .catch (err) -> 
               console.log '------- error called -------' + err.resources.length
               json = err
         
    ###*
    # starts a build in the project specified using the build config
    # 
    # @param   {ocProject} openshift project
    # @param   {ocBuildConfigName} openshift build config name that is to be built
    # 
    # @returns {reqObj} a promise that will return the payload retured by the start build event
    ###

    startBuild : (ocProject, ocBuildConfigName ) ->
        urldomain = this.baseUrl()
        initBuildPath = "/apis/build.openshift.io/v1/namespaces/#{ocProject}/buildconfigs/#{ocBuildConfigName}/instantiate"
        urlString = "#{urldomain}#{initBuildPath}"
        reqObj = this.getCoreRequest()
        reqObj.uri = urlString
        reqObj.method = 'POST'
        reqObj.body = {
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
            }

        request reqObj
           .then (response) -> 
               #console.log response
               json = response
               #console.log JSON.stringify(response, undefined, 2)
               return response
           .catch (err) -> 
               console.log '------- error called -------'
               console.log err
               json = err

    ###*
    # Gets the data from a build instantiate event (type: build), and extracts the build config name
    # to define the end point for the build that is to be watched.
    # 
    # @param   {ocProject} openshift project
    # @param   {buildData} the payload returned by the instantiate (start build) event
    # 
    # @returns {oboePromise} a promise that will untimately yield the results of the watch
    #                        event that concludes the build 
    ###
    watchBuild : (ocProject, buildData)->
        urldomain = this.baseUrl()
        reqObj = this.getCoreRequest()
        delete reqObj.json
        watchBuildUrl = "#{urldomain}/apis/build.openshift.io/v1/watch/namespaces/#{ocProject}/builds/#{buildData.metadata.name}"
        watchBuildUrl = watchBuildUrl + "?timeoutSeconds=#{requestTimeoutSeconds}"
        reqObj.url = watchBuildUrl
        oboePromise = new Promise (resolve) ->
            recordtype = undefined
            phase = undefined
            buildname = undefined
            oboeRequest = oboe(reqObj)
                .node('*', (node, path) ->
                    console.log "path: #{path}, #{typeof path}, #{path.length}, #{Array.isArray(path)}"
                    # extracting the required data from the stream
                    if ( path.length == 1) and path[0] == 'type'
                        # type is the first value of the object so putting 
                        # other values to undefined so they can be repopulated
                        # if this condition is satisfied it indicates a new record has
                        phase = undefined
                        buildname = undefined
                        cnt = cnt + 1
                        recordtype = node

                    else if (path.length == 3) and _.isEqual(path, ["object", "status", "phase"])
                        # extracting the phase value
                        phase = node
                        console.log "-------- phase: #{phase}"
                    else if (path.length == 3) and _.isEqual(path, ["object", "metadata", "name"])
                        buildname = node
                        console.log "-------- buildname: #{buildname}"

                    # Evaluating the extracted data.
                    #if recordtype == 'ADDED' and phase == 'New'
                    # First make sure we have read enough from the stream
                    if (buildname != undefined and phase != undefined) and \
                            recordtype == 'MODIFIED' and ( phase in ['Complete', 'Cancelled', 'Failed'])
                        console.log "returning data: #{recordtype} #{phase}"
                        this.abort()
                        resolve [recordtype, phase, buildname]
                        #this.done()
                )
                .fail( ( errorReport ) ->
                    console.log "status code: #{errorReport.statusCode}"
                )
                .done( () ->
                    console.log "done")
        return oboePromise

    ###*
    # Initates and monitors the build for the specified project / buildconfig
    # and returns a status object
    # 
    # @param  {ocProject} openshift project
    # @param  {ocBuildConfigName} the build config that is to be run and monitored
    # @returns {status} a status object with the properties associated with this 
    #                   build
    ###
    buildSync : (ocProject, ocBuildConfigName) ->
        buildPromise = await this.startBuild(ocProject, ocBuildConfigName)
        console.log("buildPromise #{buildPromise}, #{typeof buildPromise}")
        console.log("buildPromise #{JSON.stringify(buildPromise)}, #{typeof buildPromise}")
        watchBuildStatus = await this.watchBuild(ocProject, buildPromise)
        console.log "---watchBuild---: #{watchBuildStatus} #{typeof watchBuildStatus}"
        console.log JSON.stringify(watchBuildStatus)
        # the third value in watchBuildStatus will be the name of the build, now get the 
        # payload for that build and add to the status object
        return watchBuildStatus

    getDeployedImageSync : (ocProject, deployConfig) ->
        imageName = await this.getDeployedImage(ocProject, deployConfig)
        console.log "imageName after await: #{imageName}"

    getLatestBuildImage : (ocProject, ocBuildConfigName) ->
        # ocProject: name of the openshift project
        # ocBuildConfigName: build config name
        #
        # returns: a promise with the most recently build image
        #   name / identifier.. looks something like this:
        # docker-registry.default.svc:5000/databcdc/bcdc-test-dev@sha256:edcf5c6221be569a366cc09034bfdc2986f37d18c6b269790b0185b238f19c81
        #
        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/oapi/v1/namespaces/#{ocProject}/builds/"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString

        return request reqObj
           .then (response) -> 
                console.log "build request ----- "
                latestBuild = undefined
                latestBuildDate = undefined
                imageName = undefined
                for item in response.items
                    #console.log "item: #{JSON.stringify(item)}"
                    console.log "buildconfig: #{item.metadata.labels.buildconfig}"
                    console.log "phase: #{item.status.phase}"
                    console.log "phase: #{item.metadata.labels.buildconfig}"
                    if item.metadata.labels.buildconfig == ocBuildConfigName and \
                            item.status.phase == 'Complete'
                        console.log "passed conditional"
                        curentBuildDate = new Date(item.status.completionTimestamp)
                        if latestBuildDate == undefined
                            latestBuildDate = curentBuildDate
                            latestBuild = item.status.outputDockerImageReference
                            imageDigest = item.status.output.to.imageDigest
                        else if curentBuildDate > latestBuildDate
                            console.log "found the the build: #{latestBuildDate} #{curentBuildDate}" 
                            latestBuildDate = curentBuildDate
                            latestBuild = item.status.outputDockerImageReference
                            imageDigest = item.status.output.to.imageDigest
                            # latest build is something like this:
                            # docker-registry.default.svc:5000/databcdc/bcdc-test:latest
                            # need to combine with the property status.output.to.imageDigest
                            # to create docker-registry.default.svc:5000/databcdc/pipeline-bot@sha256:56f2a697134f04e1d519e7d063c0c0da7832e5fe0f3f007d10edf5f1b05b8724
                        re = new RegExp('\:latest$')
                        endPos = latestBuild.search(re)
                        console.log "latestBuild: #{latestBuild}"
                        if endPos != -1
                            console.log "imageName: #{imageName}"
                            imageName = "#{latestBuild.slice(0, endPos)}@#{imageDigest}"
                        else
                            console.log "#{latestBuild}   -   #{imageDigest}"
                        console.log "imagename: #{imageName}"
                return imageName
           .catch (err) -> 
               console.log '------- error called -------' + err
               json = err

    isLatestImageDeployed : (ocProject, buildConifg, deployConfig) ->
        # ocProject: the openshift project
        # ocBuildConfigName: a build config name
        # deployConfig: a deployment config
        # 
        # using the build config, identifies the last image that was build
        # using the depoly config identifies the image that is currently 
        # deployed.  If they are the same returns true otherwise returns
        # false.
        currentDeployedImage = await this.getDeployedImage(ocProject, deployConfig)
        mostRecentlyBuildImage = await this.getLatestBuildImage(ocProject, buildConifg)
        console.log "#{currentDeployedImage}  currentDeployedImage"
        console.log "#{mostRecentlyBuildImage}  mostRecentlyBuildImage"
        return currentDeployedImage == mostRecentlyBuildImage

    getDeployedImage : (ocProject, deployConfig) ->
        # ocProject: openshift project name
        # deployConfig; Deployconfig name
        #
        #  queries deploymentconfigs for the last deployment, ie replication
        #  controller number
        #
        #  queries the current replication controller for the image that was deployed.
        #
        #  returns a promise with the image name that is currently deployed.
        #
        imageName = undefined

        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/oapi/v1/namespaces/#{ocProject}/deploymentconfigs/#{deployConfig}/status"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString

        return request reqObj
         .then (response) -> 
                replicationController = "#{deployConfig}-#{response.status.latestVersion}"
                console.log "replication controller: #{replicationController}"
                apiEndPoints = "/api/v1/namespaces/#{ocProject}/replicationcontrollers/#{replicationController}"
                urlString = "#{urldomain}#{apiEndPoints}"
                repContReq = reqObj
                repContReq.uri = urlString
                repControllerRequest = request repContReq
                .then (response) ->
                    containers = response.spec.template.spec.containers
                    #console.log "containers: #{containers}"
                    for container in containers
                        console.log  "container name: #{container.name}"
                        #console.log "container: #{JSON.stringify(container)}"
                        if container.name == deployConfig
                            imageName = container.image
                            console.log "image name: #{imageName}"
                            return imageName
           .catch (err) -> 
               console.log '------- error called -------' + err
               json = err

    deploy : (ocProject, deployConfig) ->
        # ocProject: the openshift project
        # deployConfig: the deployment config to be deployed
        #
        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/apis/apps.openshift.io/v1/namespaces/#{ocProject}/deploymentconfigs/#{deployConfig}/instantiate"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        reqObj.method = 'POST'
        reqObj.headers.Content-type = "application/json"
        reqObj.body = {
            "kind":"DeploymentRequest",
            "apiVersion":"apps.openshift.io/v1",
            "name":"#{deployConfig}",
            "latest":true,
            "force":true}
        return request reqObj

    delay : (waittime) ->   
        ms = new Promise (resolve) ->
            setTimeout(resolve, waittime)

    deployWatch : (ocProject, replicationControllerName, cnt=0) ->
        # ocProject: openshift project
        # replicationControllerName: the name of the replication controller to monitor
        #
        #  monitors the replication controller until the status.replicas is equal 
        # to spec.replicas
        maxIterations = 5
        timeBetweenIterations = 5000
        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/api/v1/namespaces/#{ocProject}/replicationcontrollers/#{replicationControllerName}"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        repQuery = await request reqObj

        console.log "repQuery: #{JSON.stringify(repQuery)}"
        console.log("#{repQuery.spec.replicas} ?= #{repQuery.metadata.annotations["kubectl.kubernetes.io/desired-replicas"]}")
        # Code below is monitoring the target replicas vs the actual
        # replicas... waits until they are equal
        #
        # Possible source of target pods: repQuery.metadata.annotations["kubectl.kubernetes.io/desired-replicas"]
        # and.. repQuery.spec.replicas
        if repQuery.spec.replicas == repQuery.status.replicas
            return {'status': 'success', \
                    'replicationController': repQuery}
        else if cnt > maxIterations
            console.log("max attempts exceeded #{cnt}")
            return {'status': 'failed', \
                    'replicationController': repQuery}
        else
            cnt = cnt + 1
            console.log("attempting await")
            await this.delay(timeBetweenIterations)
            console.log("await complete")
            this.deployWatch(ocProject, replicationControllerName, cnt)

    deployLatest : (ocProject, buildConfig, deployConfig) ->
        # Checks to see if the latest build is the version that is 
        # currently deployed, and if it is stops, otherwise proceeds
        # with a deployment.
        isLatest = await this.isLatestImageDeployed(ocProject, buildConfig, deployConfig)
        if !isLatest
            deployObj = await this.deploy(ocProject, deployConfig)
            replicationController = "#{deployObj.metadata.name}-#{deployObj.status.latestVersion}"

            
            # need to get the replication controller from the payload
            # then use to query the replication controller here
            # curl -k \
            # --keepalive-time 300 \
            # -H "Authorization: Bearer $APIKEY" \
            # -H 'Accept: application/json' \
            # https://$DOMAIN/api/v1/namespaces/$PROJECT/replicationcontrollers/pipeline-bot-71

            
###*
# Class that keeps track of what actions have been performed and what their
# statuses are.
#  action:
#    - build
#    - buildwatch
#    - deploy
#    - deploywatch
#
#  status:
#    - completed
#    -
#    - failed
#    - running
#    - initiated
#
# payload:
#   The last js object returned by the last operation relating to the action
###
class OCStatus
    constructor: () ->
        @statuses = {}

    addNewStatus: (action, status) ->
        if @statuses[action] == undefined
            @statuses[action] = {}
        @statuses[action]['status'] = status

    setPayload: (action, payload) ->
        @statuses[action]['payload'] = payload
    