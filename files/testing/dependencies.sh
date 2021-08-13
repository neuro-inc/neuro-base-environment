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
nvtop --version

jupyter --version
tensorboard --version

gcloud --version
aws --version
tqdm --version

service cron status

wandb --version

neuro --version
neuro-extras --version
neuro-flow --version
neuro config show
