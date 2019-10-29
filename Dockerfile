FROM node:9


RUN useradd -m -s /bin/bash hubot-matteruser

RUN mkdir -p /usr/src/hubot-matteruser
RUN chown hubot-matteruser:hubot-matteruser /usr/src/hubot-matteruser
RUN chown hubot-matteruser:hubot-matteruser /usr/local/lib/node_modules/
RUN chown hubot-matteruser:hubot-matteruser /usr/local/bin/


WORKDIR /usr/src/hubot-matteruser

RUN git clone https://github.com/craigrigdon/pipeline-bot.git /usr/src/hubot-matteruser
USER hubot-matteruser

RUN npm install -g

USER root
RUN chmod 755 "./bin/hubot"
RUN ls -l

ENTRYPOINT ["./bin/hubot"]
