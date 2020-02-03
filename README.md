# Pipeline-bot

A Hubot CI/CD Pipeline Bot for Openshift Container Platform (OCP) with Mattermost adapter.

## Overview
The goal of this project is to automate our CI/CD pipelines for Applications built and deployed on Openshift Container Platform in order to increase deployment velocity. A ChatOps approach increases visibility and gives distributed developers more freedom to test and deploy.  

This project is based on a Dev, Test, Stage, Prod deployment model to meet our needs, but could be adapted to any workflow. 

This document will break down the build config and deployment steps required to run pipeline-bot.

## Work in Progress
* Currently expanding OCP api calls to include build from template and watch
* add responders to include git checkout and deploy to teardown environments in OCP
* output formatting to Mattermost

## Automated Workflow Steps 
1. Github Action - On closed PR (github action "Push")to DEV branch - send Hubot payload with env param
2. Hubot - receive github payload - verify pipeline has been defined
3. Hubot - build and deploy - Openshift or jenkins 
4. Hubot - start post deploy - post deployment tasks as OCP template job
5. Hubot - start test - start tests as OCP template job
6. Hubot - receive test payload - associate test results with pipeline
7. Hubot - promote - if conditions pass then promote to next environment 

# Post Deployment Stage
Currently defined in [post deploy script](post-deploy-stage.coffee)
This script will define any ocp jobs that are required to run post deployment.
OCP jobs are defined as Env Var from config map. 

# Test Stage
Currently defined in [post deploy script](test-stage.coffee)
This script will define any ocp jobs that are required to run test.
OCP jobs are defined as Env Var from config map. 
   
# Build and Deploy Guide from Scratch
Step by step how to build Hubot instance from start

*HINT* see below for [build and deploy from this repo as boilerplate](#build-and-deploy-from-this-repo-as-boilerplate)

1. local install of project
    ```
    brew install node
    npm install -g yo generator-hubot
    mkdir pipeline-bot
    cd pipeline-bot
    yo hubot
    ```
2. answer questions provided at prompt required by Hubot builder
    ```
    $ Owner 'my.email@domain.bc.ca'
    $ Bot name 'pipeline-bot'
    $ Description 'CI/CD Pipeline Bot'
    $ Bot adapter 'matteruser'
    ```
3. enable `git` on local project dir
4. update dependencies 
    * update package.json with appropriate fields and values. see example in repo 
    * update external-scripts.json with appropriate packages. see example in repo
5. commit changes on local project
6. create remote github repo and push to remote
7. create new imagestream in OCP

    `oc create imagestream pipeline-bot`
8. create tag for imagestream in OCP

    `oc tag pipeline-bot pipeline-bot:latest`
9. create new build using Source Build Strategy in OCP

    `oc new-build nodejs:10~https://github.com/bcgov/pipeline-bot.git -l app=bot`
10. required env var in deployment config via secrets or config maps 
    ```
    MATTERMOST_HOST= <url-to-mattermost> 
    MATTERMOST_GROUP= <mattermost-group>
    MATTERMOST_USER= <mattermost-username>
    MATTERMOST_PASSWORD= <mattermost-password>
    HUBOT_MATTERMOST_CHANNEL= <mattermost-channel>
    HUBOT_OCPAPIKEY= <ocp-token>
    HUBOT_OCPDOMAIN= <ocp-domain>
    HUBOT_ACL= <conifg for access control list> # see Access Control
    HUBOT_DEV_APITEST_TEMPLATE= <url-to-test-template.json>
    HUBOT_TEST_APITEST_TEMPLATE= <url-to-test-template.json>
    HUBOT_TEST_NAMESPACE= <ocp-namespace-to-run-test-in>
    HUBOT_CONFIG_PATH= <url-to-config-map> # see Pipeline Config
    HUBOT_GITHUB_TOKEN= <github token for repo access>
    ```
11. first time deploy in OCP

    `oc new-app pipeline-bot:latest`

12 . github action on repo:
   ##### github secret requirements:
   ```
   BOT_KEY= <gateway token>
   BOT_URL= <url to Bot instance>
   ```

   Example: github action to send to Hubot

    ```
    name: dev_push

    on:
      push:
        branches:
          - dev
    
    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@master
          with:
            ref: dev
        - name: Send Payload
          run: |
            curl -X POST -H "Content-Type: application/json" -H "apikey: ${{ secrets.BOT_KEY }}" -d @$GITHUB_EVENT_PATH https://${{ secrets.BOT_URL }}/hubot/github/dev
        
    ```

# Access Control
https://github.com/emptywee/acl-hubot

define config map in OCP and injected as env var `HUBOT_ACL` required for scripts/acl.coffee 

```
{
        "groups":
        {
                "admins": [ "<mattermost-username-1>", "mattermost-username-2", "mattermost-username-3"]
        },
  "commands":
  {
    "restricted":
    {
      "build": [ "admins" ],
      "deploy": [ "admins" ],
      "brain": [ "admins" ],
      "buildanddeploy": [ "admins" ]
    }
  }
}
```

# Pipeline Config
Hubot will reference this file to lookup buildconfig and deployment configs, 
and namespaces required to make the api calls to OCP or Jenkins Job Name.

Please see [Reference Config File](config.json)

Example:
```
{
  "pipelines": [
    {
      "name": "<appName>",
      "repo": "<user/repo>",
      "dev": {
        "build": {
          "buildconfig": "<ocp-bc-name>",
          "namespace": "<ocp-bc-namespace>"
        },
        "deploy": {
          "deployconfig": "<ocp-dc-name>",
          "namespace": "<ocp-dc-namespace>"
        }
      },
      "test": {
        "build": {
          "buildconfig": "<ocp-bc-name>",
          "namespace": "<ocp-bc-namespace>"
        },
        "deploy": {
          "deployconfig": "<ocp-dc-name>",
          "namespace": "<ocp-dc-namespace>"
        }
      },
      "prod": {
        "build": {
          "jenkinsjob":"job/jenkins-job-path/"
        }
      }
    }
  ]
}

```

# Other Notes
### Dockerfile
dockerfile in this repo is for local build development only and not to be used for production.

### Test Dir
currently used for test scripts and example test routes for local testing and examples only.

### Data Dir
payload examples for references from  github and OCP sources, includes readme with curl examples.  

# Custom Responders
Hubot allows us to create custom responders to interact directly with the bot.

defined in scripts/responders.coffee

A list of commands are available by running `cmd <hubotname> help`

# Build and deploy from this repo as boilerplate
_Steps to deploy directly from fork of this repo_:

1. fork this repo
2. change bot name
    update -name argument in both files
    * /bin/hubot
    * /bin/hubot.cmd
    
    `exec node_modules/.bin/hubot --name "<my-bot-name>" "$@"`
3. create new build using Source Build Strategy in OCP

    `oc new-build nodejs:10~https://github.com/<forked/repo>.git -l app=bot`
4. define required env var in deployment config via secrets or config maps 
    * as listed above
5. define access control list as config map
    * as listed above
6. define pipeline config map
    * as listed above
7. first time deploy in OCP

    `oc new-app pipeline-bot:latest`
