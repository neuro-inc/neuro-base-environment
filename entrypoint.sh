#!/usr/bin/env bash

if [ ! -z "$EXPOSE_SSH" ]; then
  echo "Starting SSH server"
  /usr/sbin/sshd -e
fi

# run command
exec "$@"
