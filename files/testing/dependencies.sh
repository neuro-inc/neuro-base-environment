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
wandb --version

aws --version
tqdm --version

service cron status

apolo --version
apolo-extras --version
apolo-flow --version
apolo config show

# sanity check of python libs
python -c "import scipy as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import pandas as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import cloudpickle as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import sklearn as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import matplotlib as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import PIL as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import jupyterlab as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import tqdm as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import cv2 as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"

# environment specific dependencies check
conda activate tf
python -c "import tensorflow as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
conda deactivate
conda activate torch
python -c "import torchvision as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
python -c "import torchaudio as pkg; print(f'{pkg.__package__} version: {pkg.__version__}')"
conda deactivate
pip check -v
### Framework-specific tests
# test gpu availability in DL frameworks, activating conda envs


conda activate tf
python gpu_tensorflow.py

# execute TF beginners notebook
wget -q https://raw.githubusercontent.com/tensorflow/docs/refs/heads/master/site/en/tutorials/quickstart/beginner.ipynb -O beginner.ipynb
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 beginner.ipynb
rm beginner.ipynb
conda deactivate

conda activate torch
python gpu_pytorch.py

# execute Pytorch quickstart notebook
wget -q https://pytorch.org/tutorials/_downloads/c30c1dcf2bc20119bcda7e734ce0eb42/quickstart_tutorial.ipynb -O quickstart_tutorial.ipynb
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 quickstart_tutorial.ipynb
rm quickstart_tutorial.ipynb
conda deactivate
