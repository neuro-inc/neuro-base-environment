#!/bin/sh
if ! command -v nvcc >/dev/null 2>&1; then
  echo "====== applying libdevice fix ======"
  # (A.K.) Need to install nvcc since it provides libdevice.10.bc
  # This adds less than 100MB to the image size
  # Adapted from https://www.tensorflow.org/install/pip#ubuntu_2204
  conda install -y -c nvidia cuda-nvcc=11.3.58 && \
  mkdir -p /usr/local/cuda/nvvm/libdevice && \
  ln -s /opt/conda/nvvm/libdevice/libdevice.10.bc /usr/local/cuda/nvvm/libdevice/ && \
  echo "====== libdevice fix applied ======"
fi
