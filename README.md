# Pipeline-bot

A Hubot CI/CD Pipeline Bot 

# Requirements
  1. matteruser adapter for hubot requires the below env var to be defined at the deployment stage
  * MATTERMOST_HOST=<url-to-mattermost> 
  * MATTERMOST_GROUP=<mattermost-group>
  * MATTERMOST_USER=<mattermost-username>
  * MATTERMOST_PASSWORD=<mattermost-password>

# Step by Step build guide for Hubot and deployment to Openshift

## 1. local install of project
```
brew install node
npm install -g yo generator-hubot
mkdir pipeline-bot
cd pipeline-bot
yo hubot
```
## 2. answer questions provided at prompt required by hubot builder
```
$ Owner 'craig.rigdon@gov.bc.ca'
$ Bot name 'pipeline-bot'
$ Description 'CI/CD Pipeline Bot'
$ Bot adapter 'matteruser'
```
## 3. enable git on local project dir

## 4. update files
* update package.json with appropriate fields and values. see example in repo 
* update external-scripts.json with appropriate packages. see example in repo

## 5. commit changes on local project
## 6. create remote github repo and push to remote

## 7. create new imagestream in OCP
```
oc create imagestream pipeline-bot
```
## 8. create tag for imagestream in OCP
```
oc tag pipeline-bot pipeline-bot:latest
```

## 9. create new build using Source Build Strategy in OCP
```
oc new-build nodejs:10~https://github.com/craigrigdon/pipeline-bot.git -l app=bot
```


## 10. first time deploy in OCP
```
oc new-app pipeline-bot:latest
```
#### define matteruser adapter env var at deployment stage for container via secretes and config maps within OCP
  * MATTERMOST_HOST=<url-to-mattermost> 
  * MATTERMOST_GROUP=<mattermost-group>
  * MATTERMOST_USER=<mattermost-username>
  * MATTERMOST_PASSWORD=<mattermost-password>

## 11. future incremental builds, will trigger new deployment after successful build.
```
oc start-build pipeline-bot
```


# Dockerfile
*dockerfile in repo is for local build development only and not to be used for production. 
