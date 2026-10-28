# wildduck-haraka-inbound

Inbound MX image: [Haraka](https://haraka.github.io/) with
[haraka-plugin-wildduck](https://github.com/zone-eu/haraka-plugin-wildduck),
delivering incoming mail into [WildDuck](https://wildduck.email/).

```
ghcr.io/codemowers/wildduck-haraka-inbound
```

The image ships a complete Haraka config in `/etc/haraka`, so it runs without
mounting any config files. Settings that differ between deployments come
from environment variables.

## Built-in config

`haraka -i` installs Haraka's defaults, and [`haraka/config`](haraka/config)
is copied on top of them:

| File             | Contents                                                   |
| ---------------- | ---------------------------------------------------------- |
| `plugins`        | `spf`, `clamd`, `rspamd`, `dkim_verify`, `wildduck`, `tls` |
| `smtp.ini`       | listen on `[::0]:2525`, 1 worker                           |
| `tls.ini`        | key `/cert/tls.key`, cert `/cert/tls.crt`, DH parameters `/dhparams/dhparams.pem` |
| `rspamd.ini`     | rspamd at `rspamd:11333`                                   |
| `clamd.ini`      | clamd at `clamav:3310`, rejects viruses                    |
| `queue_dir`      | `/var/lib/haraka/queue`                                    |
| `plugin_timeout` | 180 seconds                                                |
| `wildduck.js`    | plugin defaults with `WILDDUCK_*` env overrides (below)    |

## Environment variables

### `WILDDUCK_*`: wildduck plugin settings

The plugin's bundled
[`wildduck.yaml`](https://github.com/zone-eu/haraka-plugin-wildduck/blob/master/config/wildduck.yaml)
supplies the defaults. A `WILDDUCK_*` variable overrides one key:

- Use `__` between nested keys. Keys are case-sensitive and must match the
  YAML.
- Values are parsed as JSON when possible, so numbers, booleans and arrays
  get the right type. Anything else is kept as a string.

```sh
WILDDUCK_mongo__url=mongodb://user:pass@mongo:27017/wildduck
WILDDUCK_mongo__sender=wildduck
WILDDUCK_redis=redis://redis:6379/3
WILDDUCK_srs__secret=...
WILDDUCK_sender__enabled=false
WILDDUCK_rspamd__blacklist='["DMARC_POLICY_REJECT"]'
WILDDUCK_rspamd__responses__RBL_ZONE='[{host}] was found from Zone RBL'
```

A value made only of digits becomes a number. To keep it a string (a
password, for example), quote it as JSON: `WILDDUCK_srs__secret='"12345"'`.

`APPCONF_*` variables have no effect. The plugin turns off WildDuck's own
config loader (`wild-config`) and reads its settings only through Haraka.

### `HARAKA_ME`: server hostname

Sets the hostname Haraka uses in its SMTP banner and in `Received` headers,
for example `mail.example.com`. If it is unset, Haraka uses the container
hostname.

## Runtime requirements

- Runs as uid 65534 and works with a read-only root filesystem.
- `/var/lib/haraka` must be writable. It holds the queue and the `me` file
  that the entrypoint writes from `HARAKA_ME`.
- Mount the TLS key and certificate at `/cert/tls.key` and `/cert/tls.crt`,
  for example from a Kubernetes TLS Secret.
- Mount DH parameters at `/dhparams/dhparams.pem`. The image does not ship
  them, so every deployment uses its own. Generate them with
  `openssl dhparam -out dhparams.pem 2048` and store them in a Secret (see
  [this Job](https://github.com/codemowers/kube/blob/main/wildduck/templates/dhparam.yaml)).
  If the file is missing, Haraka tries to generate it at startup with
  `openssl`, which the image does not include, so startup fails.

## Kubernetes example

```yaml
containers:
  - name: haraka
    image: ghcr.io/codemowers/wildduck-haraka-inbound:<tag>
    ports:
      - containerPort: 2525
    securityContext:
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 65534
    env:
      - name: HARAKA_ME
        value: mail.example.com
      - name: WILDDUCK_mongo__url
        valueFrom: { secretKeyRef: { name: mongodb, key: MONGO_URI } }
      - name: WILDDUCK_redis
        valueFrom: { secretKeyRef: { name: redis, key: REDIS_URI } }
      - name: WILDDUCK_srs__secret
        valueFrom: { secretKeyRef: { name: srs, key: secret } }
    volumeMounts:
      - { name: var-lib-haraka, mountPath: /var/lib/haraka }
      - { name: cert, mountPath: /cert }
      - { name: dhparams, mountPath: /dhparams }
volumes:
  - name: var-lib-haraka
    emptyDir: {}
  - name: cert
    secret: { secretName: mail-tls }
  - name: dhparams
    secret: { secretName: dhparams }
```

## Using your own config

Mounting a directory over `/etc/haraka` (and `/etc/haraka/config`) replaces
the built-in config completely, and Haraka then works the same way as in
earlier versions of this image. Anything you mount must include every file
Haraka needs, such as `smtp.ini` and `connection.ini`. Haraka does not fall
back to its bundled defaults for missing files.

To change only the plugin list or an `.ini` file, edit
[`haraka/config`](haraka/config) and rebuild the image.
