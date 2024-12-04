ARG BASE_IMAGE=nvidia/cuda:12.6.2-cudnn-devel-ubuntu24.04
FROM ${BASE_IMAGE}
ENV LANG C.UTF-8
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    apt-get update -qq && \
# ==================================================================
# tools
# ------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        cron \
        curl \
        git \
        libssl-dev \
        python3-dev \
        python3-pip \
        python3-venv \
        rsync \
        rclone \
        unrar \
        zip \
        unzip \
        vim \
        wget \
        libncurses5-dev \
        libncursesw5-dev \
        libglib2.0-0 \
        gcc \
        make \
        cmake \
        nano \
        tmux \
        htop \
        ssh \
        && \
        # NVTop >>
        git clone --depth 1 --branch 1.2.2 -q https://github.com/Syllo/nvtop.git nvtop && \
        mkdir -p nvtop/build && cd nvtop/build && \
        cmake --log-level=WARNING .. && \
        make --quiet install && \
        cd ../.. && rm -r nvtop && \
        # <<
        ln -s $(which python3) /usr/bin/python && \
        # Git-LFS >>
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
        DEBIAN_FRONTEND=noninteractive $APT_INSTALL git-lfs && \
        # <<
        # Remove PyYAML before other pip tools installation
        # since APT installs outdated PyYAML as dist package, which breaks pip's deps management
        # https://stackoverflow.com/questions/49911550/how-to-upgrade-disutils-package-pyyaml
        rm -rf /usr/lib/python3/dist-packages/yaml && \
        rm -rf /usr/lib/python3/dist-packages/PyYAML-* && \
        apt-get clean && \
        apt-get autoremove -y --purge && \
        rm -rf /var/lib/apt/lists/* /tmp/* ~/*
# ==================================================================
# python
# ------------------------------------------------------------------
COPY requirements/python.txt /tmp/requirements/python.txt
COPY libdevice_fix.sh /tmp/libdevice_fix.sh

# ==================================================================
# torch
# ------------------------------------------------------------------
COPY requirements/torch.txt /tmp/requirements/torch.txt

# ==================================================================
# tf
# ------------------------------------------------------------------
COPY requirements/tf.txt /tmp/requirements/tf.txt
# ==================================================================
# Miniconda
# ------------------------------------------------------------------
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py311_24.9.2-0-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    . /opt/conda/etc/profile.d/conda.sh && \
    conda activate base && \
    . /tmp/libdevice_fix.sh && \
# ==================================================================
# Python
# ------------------------------------------------------------------
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL pip pipx && \
    python3 -m pipx ensurepath && \
    $PIP_INSTALL -r /tmp/requirements/python.txt --extra-index-url https://download.pytorch.org/whl && \
    conda install --channel conda-forge nb_conda_kernels==2.5.1 && \
# ==================================================================
# Create a Separate Conda Environment for TORCH
# ------------------------------------------------------------------
    conda create -y -n torch python=3.11 && \
    conda activate torch && \
    $PIP_INSTALL -r /tmp/requirements/python.txt && \
    $PIP_INSTALL -r /tmp/requirements/torch.txt --extra-index-url https://download.pytorch.org/whl && \
    conda deactivate && \
# ==================================================================
# Create a Separate Conda Environment for TENSORFLOW
# ------------------------------------------------------------------
    conda create -y -n tf python=3.11 && \
    conda activate tf && \
    $PIP_INSTALL -r /tmp/requirements/python.txt && \
    $PIP_INSTALL -r /tmp/requirements/tf.txt && \
    conda deactivate && \
# ================================================================== \
# Remove the requirements folder \
# ------------------------------------------------------------------ \
    rm -r /tmp/requirements && \
# ==================================================================
# VSCode server
# ------------------------------------------------------------------
    wget -q https://github.com/cdr/code-server/releases/download/v3.11.1/code-server_3.11.1_amd64.deb && \
    dpkg -i code-server_3.11.1_amd64.deb && \
    rm code-server_3.11.1_amd64.deb
# ==================================================================
# OOM guard
# Adds a script to tune oom_killer behavior and puts it into the crontab
# ==================================================================
COPY files/usr/local/sbin/oom_guard.sh /usr/local/sbin/oom_guard.sh
RUN crontab -l 2>/dev/null | { cat; echo '* * * * * /usr/local/sbin/oom_guard.sh'; } | crontab

# ==================================================================
# Documentation notebook
# ------------------------------------------------------------------
RUN mkdir -p /var/notebooks
COPY files/var/notebooks/README.ipynb /var/notebooks

# ==================================================================
# Set up SSH for remote debug
# ------------------------------------------------------------------

# Setup environment for ssh session
RUN apt-get install -y --no-install-recommends openssh-server && \
    echo "export PATH=/root/.local/bin:$PATH" >> /etc/profile && \
    echo "export LANG=$LANG" >> /etc/profile && \
    echo "export LANGUAGE=$LANGUAGE" >> /etc/profile && \
    echo "export LC_ALL=$LC_ALL" >> /etc/profile && \
    echo "export PYTHONIOENCODING=$PYTHONIOENCODING" >> /etc/profile && \
    . /etc/profile && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# Create folder for openssh fifos
RUN mkdir -p /var/run/sshd

# Disable password for root
RUN sed -i -re 's/^root:[^:]+:/root::/' /etc/shadow
RUN sed -i -re 's/^root:.*$/root::0:0:System Administrator:\/root:\/bin\/bash/' /etc/passwd

# Permit root login over ssh
RUN echo "Subsystem    sftp    /usr/lib/sftp-server \n\
PasswordAuthentication yes\n\
ChallengeResponseAuthentication yes\n\
PermitRootLogin yes \n\
PermitEmptyPasswords yes\n" > /etc/ssh/sshd_config

# ssh port
EXPOSE 22

# ==================================================================
# Neu.ro and other isolated via pipx Python packages
# ------------------------------------------------------------------
COPY requirements/pipx.txt /tmp/requirements/
# Used for pipx
ENV PATH=/opt/conda/bin:/root/.local/bin/:$PATH
RUN cat /tmp/requirements/pipx.txt | xargs -rn 1 pipx install && \
    pipx list --json && \
    rm -r /tmp/requirements
# ==================================================================
# config
# ------------------------------------------------------------------

RUN ldconfig

EXPOSE 8888 6006

# Force the stdout and stderr streams to be unbuffered.
# Needed for correct work of tqdm via 'neuro exec'
ENV PYTHONUNBUFFERED 1

WORKDIR /project

## Setup entrypoint
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]
