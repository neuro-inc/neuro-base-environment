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

neuro --version
neuro-extras --version
neuro-flow --version
neuro config show

# sanity check of python libs
python -c "import scipy as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import pandas as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import cloudpickle as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import sklearn as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import matplotlib as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import PIL as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import jupyterlab as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import tqdm as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import awscli as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import google.cloud.storage as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import tensorboardX as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import cv2 as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import torchvision as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import torchaudio as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
