FROM node:lts-alpine as builder
RUN apk add python3 make gcc g++ openssl
RUN npm install -g Haraka@3.1.5 haraka-plugin-wildduck@5.8.39
RUN sed -i 's/wildduck.yaml/wildduck.js/g' /usr/local/lib/node_modules/haraka-plugin-wildduck/index.js
RUN haraka -i /etc/haraka
COPY haraka /etc/haraka
RUN openssl dhparam -out /etc/haraka/config/dhparams.pem 2048
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN mkdir -p /var/lib/haraka/queue && chown -R 65534:65534 /var/lib/haraka
USER 65534
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["-c", "/etc/haraka"]
