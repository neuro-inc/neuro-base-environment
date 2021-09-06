ARG BASE_IMAGE=nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04
FROM ${BASE_IMAGE}
ENV LANG C.UTF-8
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    apt-get update && \
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
        # To pass test `jupyter lab build` (jupyterlab extensions), it needs nodejs>=12
        # See instructions https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions
        curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
        $APT_INSTALL nodejs && \
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
RUN PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL pip pipx && \
    $PIP_INSTALL -r /tmp/requirements/python.txt -f https://download.pytorch.org/whl/torch_stable.html && \
    rm -r /tmp/requirements && \
# ==================================================================
# VSCode server
# ------------------------------------------------------------------
    wget -q https://github.com/cdr/code-server/releases/download/v3.11.1/code-server_3.11.1_amd64.deb  && \
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
# Neu.ro packages + some isolated via pipx packages
# ------------------------------------------------------------------
COPY requirements/neuro.txt requirements/pipx.txt /tmp/requirements/
# Used for pipx
ENV PATH=/root/.local/bin:$PATH
RUN python -m pip --no-cache-dir install --upgrade -r /tmp/requirements/neuro.txt && \
    cat /tmp/requirements/pipx.txt | xargs -rn 1 pipx install && \
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
