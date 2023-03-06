#!/usr/bin/env bash

set -x

amazon-linux-extras install epel -y
yum -y install jq build-essential btrfs-progs sed wget git unzip lvm2 htop squashfs-tools \
  openssl-devel libuuid-devel libseccomp-devel glib2-devel \
  make automake gcc gcc-c++ kernel-devel pkg-config cryptsetup runc
#/dev/nvme1n1
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install
EBS_AUTOSCALE_VERSION=$(curl --silent "https://api.github.com/repos/awslabs/amazon-ebs-autoscale/releases/latest" | jq -r .tag_name)
cd /opt && git clone https://github.com/awslabs/amazon-ebs-autoscale.git
cd /opt/amazon-ebs-autoscale && git checkout "$EBS_AUTOSCALE_VERSION"
aws s3 cp s3://arima-hpc/test-cluster/tag.patch . && git apply tag.patch

SHARED_DRIVE_DEVICE=$(grep /shared /etc/mtab |cut -d ' ' -f 1)

umount /shared
sh /opt/amazon-ebs-autoscale/install.sh --mountpoint /shared --initial-device "$SHARED_DRIVE_DEVICE" > /var/log/ebs-autoscale-install.log 2>&1

# Install singularity
mkdir -p /shared/singularity /shared/tmp
chmod 777 /shared -R
echo 'export SINGULARITY_CACHEDIR=/shared/singularity' >> /etc/bashrc
echo 'export SINGULARITY_TMPDIR=/shared/tmp' >> /etc/bashrc

export SINGULARITY_VERSION=3.11.0
rpm -i "https://github.com/sylabs/singularity/releases/download/v$SINGULARITY_VERSION/singularity-ce-$SINGULARITY_VERSION-1.el7.x86_64.rpm"
singularity version

# Assume ec2-user for the remaining commands
# Install miniconda
cd /shared || exit
su ec2-user <<EOF
  #!/usr/bin/env bash

  set -x
  wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh
  export HOME=/home/ec2-user
  /bin/bash Miniconda3-py310_23.1.0-1-Linux-x86_64.sh -b -p /shared/miniconda3
  /shared/miniconda3/bin/conda init
  source /home/ec2-user/.bashrc

  # Install arima-tools
  git clone https://github.com/ArimaGenomics/AWS_cluster.git
  cd AWS_cluster || exit
  conda install -y -c conda-forge mamba

  mamba create -n arima-py \
    --override-channels -y \
    -c bioconda -c conda-forge -c defaults \
    --file conda-requirements-minimal.txt \
    --file conda-requirements-test.txt

  conda activate arima-py
  pip install -r pip-requirements.txt
  python setup.py develop
  arima-tools -h
EOF