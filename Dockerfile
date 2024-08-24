FROM node:lts-alpine as builder
RUN apk add python3 make gcc g++
RUN npm install -g Haraka@3.0.4 haraka-plugin-wildduck@5.8.13
RUN sed -i 's/wildduck.yaml/wildduck.js/g' /usr/local/lib/node_modules/haraka-plugin-wildduck/index.js
ENTRYPOINT ["/usr/local/bin/haraka"]
CMD ["-c", "/etc/haraka"]
