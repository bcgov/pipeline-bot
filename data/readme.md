# Overview

Contains various json files that show what different openshift 
end points return

Most of the data was mined using the openshift oc command with the
switch --loglevel=9

# End point curl examples

To run any of the following commands set the following environment 
variables before.

APIKEY
PROJECT
DOMAIN
BUILDNAME

## Start Build

[start Build response json](./start_build_response.json)

## Build Watch

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/$BUILDNAME

curl -k \
    -H "Authorization: Bearer $APIKEY" \
    -H 'Accept: application/json' \
    https://$DOMAIN/apis/build.openshift.io/v1/watch/namespaces/$PROJECT/builds/

[build watch return json](./build_watch.json)



