# Overview

Contains various json files that show what different openshift 
end points return

Most of the data was mined using the openshift oc command with the
switch --loglevel=9

# End point curl examples

To run any of the following commands set the following environment 
variables before.

* HUBOT_OCPAPIKEY - api key to use for authorization / authentication
* PROJECT - openshift project name
* HUBOT_OCPDOMAIN - The domain for the url  something.something.com
* BC_NAME - build config
* BUILDNAME - A specific build name BC_NAME with a -number

## Start Build

[start Build response json](./start_build_response.json)

## Build Watch

### Watch a specific build config:

curl -k \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/$BC_NAME

### Watch all builds in project

curl -k \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/

example output: [build_watch.json](./build_watch.json)

## list Builds

curl -k \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/oapi/v1/namespaces/$PROJECT/builds

example return object: [build_list.json](./build_list.json)

## Get a specific Build Status / payload / result

curl -k \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/oapi/v1/namespaces/$PROJECT/builds/$BUILDNAME

Same call as the *list Builds* but only returns the specified build. Example return struct: 
[build_list_single_build.json](build_list_single_build.json)

## start Deployment

curl -k -v -X POST  \
    --data '{"kind":"DeploymentRequest","apiVersion":"apps.openshift.io/v1","name":"pipeline-bot","latest":true,"force":true}' \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H "Accept: application/json, */*" \
    -H "Content-Type: application/json" \
    https://$HUBOT_OCPDOMAIN/apis/apps.openshift.io/v1/namespaces/$PROJECT/deploymentconfigs/$DEPLOY_CONFIG_NAME/instantiate

[returns a deploymentconfig object](deployment_init_payload.json)

## Get status of a deployment / replication controller

curl -k \
    --keepalive-time 300 \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$HUBOT_OCPDOMAIN/api/v1/namespaces/$PROJECT/replicationcontrollers/$DEPLOY_CONFIG_NAME-97

return json: [replication_controller.json](./replication_controller.json)


## Get status 

curl -k \
    --keepalive-time 300 \
    -H "Authorization: Bearer $HUBOT_OCPAPIKEY" \
    -H 'Accept: application/json' \
    https://$HUBOT_OCPDOMAIN/oapi/v1/namespaces/$PROJECT/deploymentconfigs/$DEPLOY_CONFIG_NAME/status

/oapi/v1/namespaces/#{ocProject}/deploymentconfigs/#{deployConfig}/status