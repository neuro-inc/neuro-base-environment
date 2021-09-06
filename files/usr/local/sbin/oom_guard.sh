#!/bin/bash

# This script ensures that the processes are going to be killed
# by the OOM Killer in the reversed order of their creation.
# Therefore, the container entrypoint and cron services
# are going to be killed at the last step

for pid in $(ps x | awk 'NR>1 {print $1}' | xargs)
do
  score=$(expr $pid - 1000)
  if [ $score -gt 1000 ]
  then
   score=1000
  fi
  echo $score > /proc/"$pid"/oom_score_adj
done
