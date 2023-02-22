#!/usr/bin/env bash

set -x

amazon-linux-extras install epel -y
yum -y install jq build-essential btrfs-progs sed wget git unzip lvm2 htop squashfs-tools \
  openssl-devel libuuid-devel libseccomp-devel glib2-devel \
  make automake gcc gcc-c++ kernel-devel pkg-config cryptsetup runc

# Install singularity
sudo chmod 777 /shared -R
mkdir -p /shared/singularity
echo 'export SINGULARITY_CACHEDIR=/shared/singularity' >> /etc/bashrc

export SINGULARITY_VERSION=3.11.0
rpm -i "https://github.com/sylabs/singularity/releases/download/v$SINGULARITY_VERSION/singularity-ce-$SINGULARITY_VERSION-1.el7.x86_64.rpm"
singularity version

# Assume user for conda install
su ec2-user -l
# Install miniconda
cd /shared || exit
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh
export HOME=/home/ec2-user/
/bin/bash Miniconda3-py310_23.1.0-1-Linux-x86_64.sh -b
/home/ec2-user/miniconda3/bin/conda init
source /home/ec2-user/.bashrc

# Install arima-tools
# TODO need to clone src
conda install -c conda-forge mamba

#mamba create -n arimapy \
#  --override-channels -y \
#  -c bioconda -c conda-forge -c defaults \
#  --file conda-requirements-minimal.txt \
#  --file conda-requirements-test.txt
#
#conda activate arimapy
#python setup.py develop
#arima-tools -h

