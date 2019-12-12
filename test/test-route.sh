#!/usr/bin/env bash

# to be used to test hubot routes during development
# you will have to change local ip and port to what you have defined in your docker port bindings for that container.

#curl -X POST -H "Content-Type: application/json" \
#-d '{"status":"success", "stage":"test"}' http://127.0.0.1:32768/hubot/test

#curl -X POST -H "Content-Type: application/json" \
#-d '{"status":"success or failed", "env":"cadi or cati here", "results":"test results here", "id":"12345"}' http://127.0.0.1:32768/hubot/apitest

payload='/Users/crigdon/PycharmProjects/pipeline-bot/data/github_payload_test.json'
curl -X POST -H "Content-Type: application/json" \
-d @$payload http://127.0.0.1:32768/hubot/github/dev

#curl -X POST -H "Content-Type: application/json"  -d "$payload" http://127.0.0.1:32768/hubot/github/dev

#PathTOJson='/Users/crigdon/PycharmProjects/pipeline-bot/data/build_deploy_response.json'
##curl -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" -d @$GITHUB_EVENT_PATH https://${{ secrets.BOT_URL }}/hubot/github
#
#MyString= | jq -Rs '.' '/Users/crigdon/PycharmProjects/pipeline-bot/data/github_payload_test.json'
##echo $MyString
#
#curl -d =$PAYLOAD -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" https://${{ secrets.BOT_URL }}/hubot/github

#working payload
#Payload=$(cat '/Users/crigdon/PycharmProjects/pipeline-bot/data/build_deploy_response.json' | jq -r -S '. + {"envKey": "dev"}')
#echo "hello"
#echo $Payload

##working payload
#payload=$(cat '/Users/crigdon/PycharmProjects/pipeline-bot/data/build_deploy_response.json')
#echo $payload
#echo $payload | jq --arg envKey dev '. + {envKey: $envKey}'
#
#curl -X POST -H "Content-Type: application/json"  -d "$payload" http://127.0.0.1:32768/hubot/github/dev
