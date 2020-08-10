#!/usr/bin/env bash

if [ ! -z "$EXPOSE_SSH" ]; then
  /usr/sbin/sshd -e
fi

# run command
exec "$@"
