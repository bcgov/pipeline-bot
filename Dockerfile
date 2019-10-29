FROM node:10-alpine
# docker file for local build development work

RUN apk update && apk upgrade \
  && apk add redis \
  && apk add --no-cache bash git openssh \
  && rm -rf /var/cache/apk/*

RUN mkdir /app
WORKDIR /app

RUN git clone https://github.com/craigrigdon/pipeline-bot.git /app

RUN npm install -g

RUN chmod 755 "./bin/hubot"
RUN ls -l

ENTRYPOINT ["/app/bin/hubot"]
