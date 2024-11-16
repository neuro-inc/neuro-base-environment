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

apolo --version
apolo-extras --version
apolo-flow --version
apolo config show

nvidia-smi
