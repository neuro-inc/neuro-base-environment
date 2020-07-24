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
tqdm --version

## Stupid W&B: `wandb --version` works in interactive mode!
## It gives you choices:
# wandb: (1) Create a W&B account
# wandb: (2) Use an existing W&B account
# wandb: (3) Don't visualize my results
## so we need to choose `3` not to visualize anything
echo 3 | wandb --version
