#!/usr/bin/env bash

# to be used to test hubot routes during development
# you will have to change local ip and port to what you have defined in your docker port bindings for that container.

curl -X POST -H "Content-Type: application/json" -d '{"status":"success", "stage":"test"}' http://127.0.0.1:32768/hubot/deployclass
