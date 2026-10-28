FROM node:lts-alpine as builder
RUN apk add python3 make gcc g++
RUN npm install -g Haraka@3.1.5 haraka-plugin-wildduck@5.8.39
RUN sed -i 's/wildduck.yaml/wildduck.js/g' /usr/local/lib/node_modules/haraka-plugin-wildduck/index.js
RUN haraka -i /etc/haraka && rm /etc/haraka/config/me
COPY haraka /etc/haraka
RUN mkdir -p /var/lib/haraka/queue && chown -R 65534:65534 /var/lib/haraka
USER 65534
# Let config/<name>.js stand in for a missing config file, e.g. me.js
ENV HARAKA_JS_CONFIG=1
ENTRYPOINT ["/usr/local/bin/haraka"]
CMD ["-c", "/etc/haraka"]
