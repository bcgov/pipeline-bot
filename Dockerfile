FROM node:lts-alpine

RUN apk update && apk upgrade \
  && apk add redis \
  && apk add --no-cache bash git openssh \
  && rm -rf /var/cache/apk/*

RUN mkdir /app
WORKDIR /app

RUN git clone https://github.com/craigrigdon/pipeline-bot.git /app
RUN npm install

RUN chmod 755 "./bin/hubot"
RUN ls -l

ENTRYPOINT ["./bin/hubot"]



