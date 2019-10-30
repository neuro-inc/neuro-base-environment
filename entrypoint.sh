#!/usr/bin/env bash

if [ "$EXPOSE_SSH" == "true" ] || [ "$EXPOSE_SSH" == "yes" ]; then
  echo "Starting SSH server"
  /usr/sbin/sshd -e
fi

ldconfig


exec timeout $JOB_TIMEOUT "$@" || [ $? -eq 124 ] && echo "Job timeout exceeded: JOB_TIMEOUT=$JOB_TIMEOUT"
