'use strict';

// Haraka reads config/me.js in place of the missing config/me because
// HARAKA_JS_CONFIG is set. Without HARAKA_ME Haraka uses the hostname.
module.exports = process.env.HARAKA_ME || null;
