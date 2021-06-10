#!/usr/bin/env bash

if [ ! -z "$EXPOSE_SSH" ]; then
  /usr/sbin/sshd -e
fi

# run services
service cron start 2>&1 >/dev/null

# run command
exec "$@"
