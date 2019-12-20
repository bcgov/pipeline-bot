# Pipeline-bot

A Hubot CI/CD Pipeline Bot for Openshift Container Platform (OCP) with Mattermost adapter.

##Overview
The goal of this project is to automate our CI/CD pipelines for Applications built 
and deployed on Openshift Container Platform to increasing deployment velocity.  A ChatOps approach
to increase visibility and give distributed developers more freedom to test and deploy.  

This project is based on a Dev, Test, Prod deployment model to meet our needs, 
but could be adapted to any workflow. 

This document will break down the build config and deployment steps required to run pipeline-bot.

##Automated Workflow Steps from DEV-to-PROD
1. Github Action - On push to DEV branch - send hubot payload with env param
2. Hubot - receive github payload - verify pipeline has been defined
3. Hubot - build deploy watch - start OCP build and watch then start deploy and watch for DEV
4. Hubot - start test - start tests as OCP job
5. Hubot - receive test payload - associate test results with pipeline
6. Hubot - promote - if conditions pass then promote to next environment TEST
7. Hubot - pull request - pull request to github repo
8. Hubot - build deploy watch - start OCP build and watch then start deploy and watch for TEST
9. Hubot - data migration - migration and sanitize PROD data to TEST
10. Hubot - start test - start test as OCP job
11. Hubot - receive test payload - associate test results with pipeline
12. Hubot - promote - if conditions pass then promote to next environment PROD
13. Hubot - merge pull request - merge pull request in github repo
14. Hubot - build deploy watch - start OCP build and watch then start deploy and watch PROD
   
# Build and Deploy Guide from Scratch
step by step how to build hubot instance from start

* HINT see below for build and deploy from this repo a boilerplate

### 1. local install of project
```
brew install node
npm install -g yo generator-hubot
mkdir pipeline-bot
cd pipeline-bot
yo hubot
```
### 2. answer questions provided at prompt required by hubot builder
```
$ Owner 'craig.rigdon@gov.bc.ca'
$ Bot name 'pipeline-bot'
$ Description 'CI/CD Pipeline Bot'
$ Bot adapter 'matteruser'
```
### 3. enable git on local project dir

### 4. update dependencies 
* update package.json with appropriate fields and values. see example in repo 
* update external-scripts.json with appropriate packages. see example in repo

### 5. commit changes on local project
### 6. create remote github repo and push to remote

### 7. create new imagestream in OCP
```
oc create imagestream pipeline-bot
```
### 8. create tag for imagestream in OCP
```
oc tag pipeline-bot pipeline-bot:latest
```
### 9. create new build using Source Build Strategy in OCP
```
oc new-build nodejs:10~https://github.com/bcgov/pipeline-bot.git -l app=bot
```
### 10. Define required env var in deployment config via secrets or config maps 
  * MATTERMOST_HOST= <url-to-mattermost> 
  * MATTERMOST_GROUP= <mattermost-group>
  * MATTERMOST_USER= <mattermost-username>
  * MATTERMOST_PASSWORD= <mattermost-password>

### 11. first time deploy in OCP
```
oc new-app pipeline-bot:latest
```
#Other Notes:
###Dockerfile
dockerfile in this repo is for local build development only and not to be used for production.
###Test Dir
currently used for test scripts and example test routes for local testing and examples only.
###Data Dir
payload examples for references from  github and OCP sources, includes readme with curl examples.  
