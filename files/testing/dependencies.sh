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

jupyter --version
tensorboard --version
wandb --version

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
python -c "import tensorboardX as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import cv2 as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import torchvision as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import torchaudio as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
pip check -v
### Framework-specific tests
# test gpu availability in DL frameworks
python gpu_pytorch.py
python gpu_tensorflow.py

# execute TF beginners notebook
wget -q https://storage.googleapis.com/tensorflow_docs/docs/site/en/tutorials/quickstart/beginner.ipynb -O beginner.ipynb
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 beginner.ipynb
rm beginner.ipynb

# execute Pytorch quickstart notebook
wget -q https://pytorch.org/tutorials/_downloads/c30c1dcf2bc20119bcda7e734ce0eb42/quickstart_tutorial.ipynb -O quickstart_tutorial.ipynb
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 quickstart_tutorial.ipynb
rm quickstart_tutorial.ipynb
