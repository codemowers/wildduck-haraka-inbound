'use strict';

// Plugin config = the plugin's bundled wildduck.yaml defaults, overridden by
// WILDDUCK_* env vars. Path segments are separated by "__", keys are
// case-sensitive, values are parsed as JSON when possible:
//   WILDDUCK_mongo__url=mongodb://mongo:27017/wildduck
//   WILDDUCK_redis__host=redis
//   WILDDUCK_sender__enabled=false
//   WILDDUCK_rspamd__blacklist='["DMARC_POLICY_REJECT"]'

const fs = require('fs');
const path = require('path');

const pluginDir = path.dirname(require.resolve('haraka-plugin-wildduck', { paths: ['/usr/local/lib/node_modules'] }));
const yaml = require(require.resolve('js-yaml', { paths: [pluginDir] }));

const config = yaml.load(fs.readFileSync(path.join(pluginDir, 'config', 'wildduck.yaml'), 'utf8'));

const parse = value => {
    try {
        return JSON.parse(value);
    } catch (err) {
        return value;
    }
};

for (const [key, value] of Object.entries(process.env)) {
    const match = key.match(/^WILDDUCK_(.+)$/);
    if (!match) {
        continue;
    }
    const keys = match[1].split('__');
    const last = keys.pop();
    let target = config;
    for (const k of keys) {
        if (!target[k] || typeof target[k] !== 'object') {
            target[k] = {};
        }
        target = target[k];
    }
    target[last] = parse(value);
}

module.exports = config;
