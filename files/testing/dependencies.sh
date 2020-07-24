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

jupyter --version
tensorboard --version
neuro --version

gcloud --version
aws --version
wandb --version
tqdm --version
