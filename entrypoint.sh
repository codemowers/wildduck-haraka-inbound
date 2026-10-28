#!/bin/sh
set -e

# The root filesystem may be read-only, so config/me is a symlink into the
# writable /var/lib/haraka. Without HARAKA_ME Haraka falls back to the hostname.
if [ -n "$HARAKA_ME" ]; then
    printf '%s\n' "$HARAKA_ME" > /var/lib/haraka/me
fi

exec /usr/local/bin/haraka "$@"
