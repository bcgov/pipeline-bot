#!/usr/bin/env bash

# to be used to test hubot routes during development
# you will have to change local ip and port to what you have defined in your docker port bindings for that container.

##### curl for test route
#curl -X POST -H "Content-Type: application/json" \
#-d '{"status":"success", "stage":"test"}' http://127.0.0.1:32768/hubot/test

##### curl for apitest route
#curl -X POST -H "Content-Type: application/json" \
#-d '{"status":"success", "env":"cadi", "results":"results", "id":"12345ABC"}' http://127.0.0.1:32768/hubot/apitest

##### curl for github route
payload='/Users/crigdon/PycharmProjects/pipeline-bot/data/github_payload_test.json'
curl -X POST -H "Content-Type: application/json" \
-d @$payload http://127.0.0.1:32768/hubot/github/test







