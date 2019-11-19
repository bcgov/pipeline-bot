# Overview

Contains various json files that show what different openshift 
end points return

Most of the data was mined using the openshift oc command with the
switch --loglevel=9

# End point curl examples

To run any of the following commands set the following environment 
variables before.

APIKEY - api key to use for authorization / authentication
PROJECT - openshift project name
DOMAIN - The domain for the url  something.something.com
BC_NAME - build config
BUILDNAME - A specific build name BC_NAME with a -number

## Start Build

[start Build response json](./start_build_response.json)

## Build Watch

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/$BC_NAME

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/



[build watch return json](./build_watch.json)

## list Builds

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/oapi/v1/namespaces/$PROJECT/builds

## Get a specific Build Status / payload / result

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/oapi/v1/namespaces/$PROJECT/builds/$BUILDNAME


## Get a deployment


## start Deployment

curl -k -v -X POST  \
    --data '{"kind":"DeploymentRequest","apiVersion":"apps.openshift.io/v1","name":"pipeline-bot","latest":true,"force":true}' \
    -H "Authorization: Bearer $APIKEY" \
    -H "Accept: application/json, */*" \
    -H "Content-Type: application/json" \
    https://$DOMAIN/apis/apps.openshift.io/v1/namespaces/$PROJECT/deploymentconfigs/$DEPLOY_CONFIG_NAME/instantiate

[returns a deploymentconfig object](./data/deployment_init_payload.json)

## watch deployment

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/apps/v1/watch/namespaces/$PROJECT/deployments/$DEPLOY_CONFIG_NAME

curl -k \
    --keepalive-time 300 \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/api/v1/namespaces/$PROJECT/replicationcontrollers/pipeline-bot-71




## Get a replicaset

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/apps/v1/namespaces/$PROJECT/replicasets
