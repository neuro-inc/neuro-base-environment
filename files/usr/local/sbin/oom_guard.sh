#!/bin/bash

# This script ensures only the process with PID = 1
# would have minimal oom_score_adj value
# That means it will only be killed by oom_killer at the last resort

for pid in $(ps x | awk 'NR>1 {print $1}' | xargs)
do
  if [ "$pid" != "1" ]
  then
    echo 1000 > /proc/"$pid"/oom_score_adj
  fi
done