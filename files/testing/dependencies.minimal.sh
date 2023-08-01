#!/bin/bash
set -xev -o pipefail

rsync --version
rclone --version

curl --version
wget --version

zip --version
unzip --help
unrar -V

vim --version
nano --version

tmux -V
ssh -V
git --version
git-lfs --version
nvtop --version

service cron status

neuro --version
neuro-extras --version
neuro-flow --version
neuro config show
