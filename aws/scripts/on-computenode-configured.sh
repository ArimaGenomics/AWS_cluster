#!/usr/bin/env bash

set -x

amazon-linux-extras install epel -y
yum -y install jq build-essential btrfs-progs sed wget git unzip lvm2 htop squashfs-tools \
  openssl-devel libuuid-devel libseccomp-devel glib2-devel \
  make automake gcc gcc-c++ kernel-devel pkg-config cryptsetup runc

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install
EBS_AUTOSCALE_VERSION=$(curl --silent "https://api.github.com/repos/awslabs/amazon-ebs-autoscale/releases/latest" | jq -r .tag_name)
cd /opt && git clone https://github.com/awslabs/amazon-ebs-autoscale.git
cd /opt/amazon-ebs-autoscale && git checkout "$EBS_AUTOSCALE_VERSION"
aws s3 cp s3://arima-hpc/test-cluster/tag.patch . && git apply tag.patch

sh /opt/amazon-ebs-autoscale/install.sh --mountpoint /working --initial-size 500 > /var/log/ebs-autoscale-install.log 2>&1

# Install singularity
echo 'export SINGULARITY_CACHEDIR=/shared/singularity' >> /etc/bashrc
echo 'export SINGULARITY_TMPDIR=/shared/tmp' >> /etc/bashrc

export SINGULARITY_VERSION=3.11.0
rpm -i "https://github.com/sylabs/singularity/releases/download/v$SINGULARITY_VERSION/singularity-ce-$SINGULARITY_VERSION-1.el7.x86_64.rpm"

singularity version

# Assume ec2-user for the remaining commands
# Install miniconda
cd /shared || exit
su ec2-user <<EOF
  export HOME=/home/ec2-user
  /shared/miniconda3/bin/conda init
  source /home/ec2-user/.bashrc

  # Test arima-tools
  arima-tools -h
EOF