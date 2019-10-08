#!/usr/bin/env bash

: "${PLATFORMAPI_SERVICE_HOST:?The image should only run in Neuromation platform due to insecure SSH configuration. Set environment variable PLATFORMAPI_SERVICE_HOST to any non-empty value to override this check.}"

ldconfig

/usr/sbin/sshd -De &

exec timeout $JOB_TIMEOUT "$@" || [ $? -eq 124 ] && echo "Job timeout exceeded: JOB_TIMEOUT=$JOB_TIMEOUT"
