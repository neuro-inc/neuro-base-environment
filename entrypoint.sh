#!/usr/bin/env bash

if [ ! -z "$EXPOSE_SSH" ]; then
  echo "Starting SSH server"
  /usr/sbin/sshd -e
fi

ldconfig

if [ "$GCP_SERVICE_ACCOUNT_KEY_PATH" ]; then
  gcloud auth activate-service-account --key-file "$GCP_SERVICE_ACCOUNT_KEY_PATH"
fi

exec timeout $JOB_TIMEOUT "$@" || [ $? -eq 124 ] && echo "Job timeout exceeded: JOB_TIMEOUT=$JOB_TIMEOUT"
