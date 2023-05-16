#!/bin/bash

set -e

# find all the gradle lockfiles on the
echo "Finding gradle lock files..."
for lockFile in `find ~/.gradle/daemon/ -name "*registry.bin.lock"` ; do
  # find all the processes that own file descriptors on the lock file
  echo -e "\tFinding processes with file descriptors on $lockFile..."
  for processID in `fuser $lockFile 2>/dev/null | grep -o -e "[0-9]\+$"` ; do
    echo -e "\t\tKilling process with PID $PID..."
    set -x # print the following statement when it's run
    kill -9 $processID
    set +x # stop printing the actual command invocations
  done
done
