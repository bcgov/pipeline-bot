###*
#  @fileOverview Wrapper methods to openshift to be used in a hubot
#                pipeline.
#
#  @author       Kevin Netherton
#
#  @requires     NPM:request-promise
#  @requires     NPM:lodash
#  @requires     NPM:oboe
#
###

request = require('request-promise')
_ = require('lodash')
oboe = require('oboe')

###*
# Class used to wrap up various openshift methods with the goal 
# of making it easy for hubot calls to interact with openshift.
###
class exports.OCAPI
    domain = null
    protocol = 'https'
    buildStatus = 'NOT STARTED'
    deployStatus = 'NOT STARTED'

    requestTimeoutSeconds = 300
    ###*
    # @param {string} domain - The domain to use in the url when communicating with 
    #                           openshift.
    # @param {string} apikey - The api key to use when making api calls
    ###
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
                    name: ocBuildConfigName,
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

        return request reqObj
           .then (response) -> 
               #console.log JSON.stringify(response, undefined, 2)
               return response
           .catch (err) -> 
               console.log "------- error: #{err}-------"
               console.log err.stack

    ###*
    # Gets the data from a build instantiate event (type: build), and extracts the build config name
    # to define the end point for the build that is to be watched.
    # 
    # @param {string} ocProject-  openshift project
    # @param {string} buildData - the payload returned by the instantiate (start build) event
    # 
    # @returns {Promise} a promise that will untimately yield the results of the watch
    #                    event that concludes the build, the promise will return a list
    #                    with the following elements
    #                            1. record type: (MODIFIED|ADDED|?) 
    #                            2. phase: (completed|cancelled|failed)
    #                            3. build name: the unique name that is assigned to this 
    #                                           build attempt
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
                    #console.log "path: #{path}, #{typeof path}, #{path.length}, #{Array.isArray(path)}"
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
    # hits the api and returns the json that is used to describe the 
    # provided build name.
    # 
    # @param {string} ocProject - the openshift project name
    # @param {object} buildData - the json returned by the instantiate build api call
    #
    # @return {Promise} - a request promise that will ultimately yield the 
    #                     concluding event to associated with the build
    ###
    getBuildStatus : (ocProject, ocBuildName) ->
        # calls build list on the specific build, returns the promise
        # that will yield the payload

        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/oapi/v1/namespaces/#{ocProject}/builds/#{ocBuildName}"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        return request reqObj
            .then (response) ->
                console.log "response is: #{response}"
                #console.log typeof response, JSON.stringify(response)
                return response
            .catch (err) ->
                console.log '------- error called -------' + err
                json = err
        
    ###*
    # Initates and monitors the build for the specified project / buildconfig
    # and returns a status object
    # 
    # @param  {ocProject} openshift project
    # @param  {ocBuildConfigName} the build config that is to be run and monitored
    # @returns {OCStatus} status-  a status object with the properties associated 
    #                              with this build
    ###
    buildSync : (ocProject, ocBuildConfigName) ->
        try
            console.log "ocProject: #{ocProject}, buildconfig: #{ocBuildConfigName}"
            watchBuildStatus = undefined
            buildPayload = await this.startBuild(ocProject, ocBuildConfigName)
            this.statuses.updateStatus('build', 'initiated', buildPayload)

            watchBuildStatus = await this.watchBuild(ocProject, buildPayload)
            this.statuses.updateStatus('build', watchBuildStatus[1])
            console.log "---watchBuild---: #{watchBuildStatus} #{typeof watchBuildStatus}"
            #console.log JSON.stringify(watchBuildStatus)

            buildStatus = await this.getBuildStatus(ocProject, watchBuildStatus[2])
            console.log "buildstatus kind: #{buildStatus.kind}"
            #console.log "buildstatus: #{JSON.stringify(buildStatus)}"

            # put the update into a promise to ensure it gets completed before the status 
            # object is returned.
            return await this.statuses.updateStatusAsync('build', buildStatus.status.phase, buildStatus)
            # create a promise in the status object and return that, with an await
            #resolve this.statuses
        catch err
            console.log "error encountered in buildSync: #{err}"
            console.log err.stack
            return await this.statuses.updateStatusAsync('build', 'error', err)

    ###*
    # Gets the latest image that was built using the specified 
    # buildconfig name
    #
    #  - iterates over all builds in the project
    #  - finds builds that used the build config name provided as arg
    #  - checks the build dates, to get the last image built 
    # 
    # @param {string} ocProject - The name of the oc project
    # @param {string} ocBuildConfigName - The name of the build config
    # @return {promise} - yields the name of the build image
    ###
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

    ###*
    # Gets the name of the last image that was built and the image
    # that is currently deployed, compares the names and returns
    # true or false indicating whether the latest image has been 
    # deployed
    #
    # @param {string} ocProject - the name of the oc project
    # @param {string} buildConifg - the name of the build config
    # @param {string} deployConfig - the name of the deploy config
    # @return {boolean} - indicator of whether the latest image built has been 
    #                     or is currently being deployed.
    ###
    isLatestImageDeployed : (ocProject, buildConifg, deployConfig) ->
        # ocProject: the openshift project
        # ocBuildConfigName: a build config name
        # deployConfig: a deployment config
        # 
        # using the build config, identifies the last image that was build
        # using the depoly config identifies the image that is currently 
        # deployed.  If they are the same returns true otherwise returns
        # false.
        # Will return true even if the replication is only part way complete
        mostRecentlyBuildImage = await this.getLatestBuildImage(ocProject, buildConifg)
        currentDeployedImage = await this.getDeployedImage(ocProject, deployConfig)
        console.log "#{currentDeployedImage}  currentDeployedImage"
        console.log "#{mostRecentlyBuildImage}  mostRecentlyBuildImage"
        return currentDeployedImage == mostRecentlyBuildImage


    ###*
    # Hits the deployment config status end point and returns json 
    # @param {string} ocProject - openshift project name
    # @param {string} deployConfig - the name of the deployment config
    # @return {object} - the json object that is returned by the end point
    ###    
    getDeploymentStatus: (ocProject, deployConfig) ->
        imageName = undefined

        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/oapi/v1/namespaces/#{ocProject}/deploymentconfigs/#{deployConfig}/status"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        console.log "getting: #{urlString}"
        return request reqObj
            .then (response) -> 
                console.log('getDeploymentStatus called')
                return response
            .catch (err) ->
                console.log "caught error #{err}"
                console.log "#{err.stack}"
        
    ###*
    # Gets the currently configured image name... looks like:
    #  docker-registry.default.svc:5000/databcdc/datapusher@sha256:2eff082c999cbe0eff08816d2b8d4d7b97e6e7d5825ca85ef3714990752b1c7c
    #
    # does this by getting the latestVersion property from the deploy config 
    # status end point, then appends the latestVersion to the end of the 
    # deployconfig name to get the replicationcontroller name
    # queries the replication controller end point to get the image that
    # that the latest replication controller deployed.
    #
    # @param {string} ocProject - the name of the oc project
    # @param {string} deployConfig - the name of the deploy config
    # @return {promise} - will yield the name of the image
    #
    ###
    getDeployedImage : (ocProject, deployConfig) ->
        imageName = undefined

        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/oapi/v1/namespaces/#{ocProject}/deploymentconfigs/#{deployConfig}/status"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        console.log "getting: #{urlString}"
        # this first request gets the "latestVersion" which oc uses to name the 
        # replication controller, then queries the status of the replication controller.
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
                    console.log "Error: Unable to get the replication controller: #{replicationController}"
                    console.log "response was: #{JSON.stringify(response)}"
           .catch (err) -> 
               console.log '------- error called -------'
               console.log "error: #{err}"
               console.log "request: #{JSON.stringify(reqObj)}"

    ###*
    # Calls the deployment instantiation end point and returns the json 
    # data 
    #
    # @param {string} ocProject - the openshift project
    # @param {deployConfig} deployConfig - The deploy config
    # @return {promise} - promise that will yield the payload from the deployment
    #                     instantiation event
    ###
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

    ###*
    # returns a promise that will wait for the specified number or seconds to 
    # complete 
    #
    # @param {number} waittime - the amount of time in milliseconds to wait
    # @return {promise} - that waits for a set amount of time
    ###
    delay : (waittime) ->   
        ms = new Promise (resolve) ->
            setTimeout(resolve, waittime)

    ###*
    # Queries the status of the replication controller and retrieves the desired 
    # number of controllers from `spec.replicas` and compares against 
    # status.replicas.  Cancels out when they are either equal, or the maxuimum
    # number of recursions is exceeded.  
    # 
    # When desired replicas vs existing replicas is not equal will wait for 
    # 5 seconds then check again.
    #
    # @param {string} ocProject - The openshift project
    # @param {replicationControllerName} - name of the replication controller
    # @param {number} cnt - Leave this parameter, it is used internally to manage
    #                       recursion depth.  Used to cancel out beyond a set 
    #                       number of iterations
    #
    ###
    deployWatch : (ocProject, replicationControllerName, cnt=0) ->
        maxIterations = 5
        timeBetweenIterations = 5000
        reqObj = this.getCoreRequest()
        urldomain = this.baseUrl()
        apiEndPoints = "/api/v1/namespaces/#{ocProject}/replicationcontrollers/#{replicationControllerName}"
        urlString = "#{urldomain}#{apiEndPoints}"
        reqObj.uri = urlString
        repQuery = await request reqObj
        this.statuses.updateStatus('deploy', 'deploying', repQuery)
        #console.log "repQuery: #{JSON.stringify(repQuery)}"
        console.log "requested replicas: #{repQuery.spec.replicas} ?= existing replicas: #{repQuery.status.replicas}"
        console.log "kubectl.kubernetes.io/desired-replicas: #{repQuery.metadata.annotations['kubectl.kubernetes.io/desired-replicas']}"
        # Code below is monitoring the target replicas vs the actual
        # replicas... waits until they are equal
        #
        # Possible source of target pods: repQuery.metadata.annotations["kubectl.kubernetes.io/desired-replicas"]
        # and.. repQuery.spec.replicas
        if repQuery.spec.replicas == repQuery.status.replicas
            console.log "requested replicas are up"
            this.statuses.updateStatus('deploy', 'success', repQuery)
            return  repQuery
        else if cnt > maxIterations
            console.log("max attempts exceeded #{cnt}")
            this.statuses.updateStatus('deploy', 'failed', repQuery)
            return repQuery
        else
            cnt = cnt + 1
            console.log("attempting await")
            await this.delay(timeBetweenIterations)
            console.log("await complete")
            this.deployWatch(ocProject, replicationControllerName, cnt)
    
    ###*
    #
    # Checks to see if the latest build is the version that is 
    # currently deployed, and if it is stops, otherwise proceeds
    # with a deployment.
    # @param {string} ocProject - The name of the openshift project
    # @param {string} buildConfig - The build config name
    # @return {object} - returns a OCStatus object
    #
    ###
    deployLatest : (ocProject, buildConfig, deployConfig) ->
        # 
        replicationController = undefined
        this.statuses.updateStatus('deploy', 'checking')
        try
            console.log "getting latest..."
            isLatest = await this.isLatestImageDeployed(ocProject, buildConfig, deployConfig)

            if !isLatest
                console.log "instantiating a deploy..."
                this.statuses.updateStatus('deploy', 'initiated')
                deployObj = await this.deploy(ocProject, deployConfig)
                replicationController = "#{deployObj.metadata.name}-#{deployObj.status.latestVersion}"
                this.statuses.updateStatus('deploy', 'initiated', deployObj)
            if replicationController == undefined
                # Getting the name of the replication controller that is doing
                # the rollout for the depolyment
                console.log "getting the replication controller name..."
                this.statuses.updateStatus('deploy', 'initiated')
                # should get the actual object instead of just the status, then could
                # update the status object
                latestDeployment = await this.getDeploymentStatus(ocProject, deployConfig)
                replicationController = "#{deployConfig}-#{latestDeployment.status.latestVersion}"
            # is latest only indicates that the deployment has already been triggered
            # code below will monitor for its completion.
            this.statuses.updateStatus('deploy', 'deploying')
            deployStatus = await this.deployWatch(ocProject, replicationController)
            return  this.statuses

            console.log "----------Deploy complete ----------"
        catch err 
            console.log "error encountered in attempt to deploy..", err
            return await this.statuses.updateStatusAsync('deploy', 'error', err)

            
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
#    - cancelled
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
    
    ###*
    # updates the status of an action, if the action has not been defined then 
    # it gets added to this object. OC status object is used to collect the 
    # statuses of a number of different actions 
    #
    # @param {string} action - a string describing the action (build | deploy)
    # @param {string} status - a string describing the status of the action (completed | cancelled | failed | running | instantiated )
    ###
    updateStatus : (action, status, payload=undefined) ->
        if @statuses[action] == undefined
            @statuses[action] = {}
        @statuses[action]['status'] = status
        if payload != undefined
            @statuses[action]['payload'] = payload
    
    ###*
    # Finds the status record that alignes with the action and updates the payload
    # associated with that action 
    # 
    # @param {string} action - a string describing the action (build | deploy)
    # @param {object} payload - an object that describes the action.. typically this
    #                           is json data returned by an oc endpoint
    ###
    setPayload : (action, payload) ->
        @statuses[action]['payload'] = payload
    
    ###*
    # @param {string} action - a string describing the action (build | deploy)
    # @param {string} status - status - a string describing the status of the 
    #                          action (completed | cancelled | failed | running |
    #                          instantiated )
    # @return {Promise} - a promise that will resolve to a reference to this
    #                     status object
    ###
    updateStatusAsync : (action, status, payload=undefined) ->
        objref = this
        return val = new Promise (resolve) ->
            objref.updateStatus(action, status, payload)
            resolve objref

