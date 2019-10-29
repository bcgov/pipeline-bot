# pipeline-bot

CI/CD Pipeline Bot


# OCP Build and Deploy
## how to create new build
```
oc new-build nodejs:10~https://github.com/craigrigdon/pipeline-bot.git -l app=bot
```
## how to start incremental builds
``` 
oc start-build pipeline-bot
```
## how to deploy from image stream (first time )
* all future deployments will be triggered by image change.
```
oc new-app pipeline-bot:latest
```
