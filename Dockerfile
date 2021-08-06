# ==================================================================
# module list
# ------------------------------------------------------------------
# python        3.7       (apt)
# jupyter       latest    (pip)
# jupyterlab    latest    (pip)
# pytorch       1.9.0     (docker-hub)
# tensorflow    2.5.0     (pip)
# caffe-cuda    latest    (apt)
# neuro-cli     21.6.3    (pip)
# neuro-flow    21.6.2   (pip)
# neuro-extras  21.3.19  (pip)
# ==================================================================

FROM pytorch/pytorch:1.9.0-cuda11.1-cudnn8-devel
ENV LANG C.UTF-8
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && \
# ==================================================================
# tools
# ------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        apt-utils \
        build-essential \
        ca-certificates \
        cron \
        curl \
        git \
        libssl-dev \
        rsync \
        rclone \
        unrar \
        zip \
        unzip \
        vim \
        wget \
        libncurses5-dev \
        libncursesw5-dev \
        cmake \
        nano \
        tmux \
        htop \
        ssh \
        # OpenCV
        libsm6 libxext6 libxrender-dev \
        # PyCaffe2
        caffe-cuda \
        && \
        # To pass test `jupyter lab build` (jupyterlab extensions), it needs nodejs>=12
        # See instructions https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions
        #curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
        #$APT_INSTALL nodejs && \
        # pytorch-utils
        #$APT_INSTALL python3-yaml && \
        # gsutils
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" >> /etc/apt/sources.list.d/google-cloud-sdk.list && \
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
        apt-get -y update && \
        $APT_INSTALL google-cloud-sdk
# ==================================================================
# python
# ------------------------------------------------------------------
COPY requirements/python.txt /tmp/requirements/python.txt
RUN PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL pip && \
    $PIP_INSTALL -r /tmp/requirements/python.txt && \
    rm /tmp/requirements/python.txt && \
# ==================================================================
# VSCode server
# ------------------------------------------------------------------
    wget https://github.com/cdr/code-server/releases/download/v3.9.1/code-server_3.9.1_amd64.deb  && \
    dpkg -i code-server_3.9.1_amd64.deb
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
 echo "export PATH=$PATH" >> /etc/profile && \
 echo "export LANG=$LANG" >> /etc/profile && \
 echo "export LANGUAGE=$LANGUAGE" >> /etc/profile && \
 echo "export LC_ALL=$LC_ALL" >> /etc/profile && \
 echo "export PYTHONIOENCODING=$PYTHONIOENCODING" >> /etc/profile

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
# Neu.ro packages
# ------------------------------------------------------------------
COPY requirements/neuro.txt /tmp/requirements/neuro.txt
RUN python -m pip --no-cache-dir install --upgrade -r /tmp/requirements/neuro.txt && \
    rm /tmp/requirements/neuro.txt
# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

EXPOSE 8888 6006

# Force the stdout and stderr streams to be unbuffered.
# Needed for correct work of tqdm via 'neuro exec'
ENV PYTHONUNBUFFERED 1

WORKDIR /

## Setup entrypoint
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]
