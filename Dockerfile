FROM node:10-alpine
# docker file for local build development work only

RUN apk update && apk upgrade \
  && apk add redis \
  && apk add --no-cache bash git openssh \
  && rm -rf /var/cache/apk/*

RUN mkdir /app

# use this option if you would like to copy from repo
#RUN git clone https://github.com/bcgov/pipeline-bot.git /app

#use this option to copy from local
COPY . /app

WORKDIR /app

RUN npm install -g

RUN chmod 755 "./bin/hubot"

ENTRYPOINT ["/app/bin/hubot"]

