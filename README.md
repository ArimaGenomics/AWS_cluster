[![build](https://github.com/fulcrumgenomics/python-snakemake-skeleton/actions/workflows/pythonpackage.yml/badge.svg)](https://github.com/fulcrumgenomics/python-snakemake-skeleton/actions/workflows/pythonpackage.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fulcrumgenomics/fgbio/blob/main/LICENSE)
[![Language](https://img.shields.io/badge/python-3.10.9-brightgreen)](https://www.python.org/downloads/release/python-3109/)

This repo contains the following, in no particular order:

- a hello world snakefile in `src/snakemake/hello_world.smk`
  - this uses the `onerror` directive to better display rule errors, in particular the last file
    lines of the rule's log
- a python toolkit (`arima-tools`) in `src/python/arimapy`
  - uses `defopt` for arg parsing
  - has custom logging in `core/logging.py`
  - has utility methods to support the above `onerror` snakemake directive in `pipeline/snakemake_utils.py`
  - has a unit test to ensure the above snakefile is runnable and generally executes the expected rules in `tests/test_hello_world.py`.
    This also includes a utility method to support running and verifying snakemake in `tests/util.py`
  - supports multiple sub-commands in `tools/__main__.py` with some nice logging when a tool fails
  - a little hello world tool in `tools/hello_world.py`


## Install arima-tools

- Ensure that you have python version >=3.9

- [Install conda][conda-link]

- Clone the repository
```bash
git clone https://github.com/ArimaGenomics/AWS_cluster.git
```

- cd to source root
```bash
cd AWS_cluster
```

- Create the `arimapy` conda environment


```console
conda create -n arimapy \
  --override-channels -y \
  -c bioconda -c conda-forge -c defaults \
  --file conda-requirements-minimal.txt \
  --file conda-requirements-test.txt
```

- Activate the `arimapy` conda environment

```bash
conda activate arimapy
```

- Install all non-conda dependencies via pip

```bash
pip install -r pip-requirements.txt
```

- Setup `awsv2` (Ensure that you have your AWS access key and secret handy)
```bash
awsv2 --install
awsv2 configure
```

- Install `arimapy` (in developer mode)

```bash
python setup.py develop
```

- Validate the installation via the help message

```bash
arima-tools -h
```

- Validate the snakemake install

```bash
snakemake --snakefile src/snakemake/hello_world.smk -j 1
```

- Create a test cluster (Replace `test-cluster` with your cluster name)
```bash
pcluster create-cluster --cluster-configuration aws/config/test-cluster-config.yaml --cluster-name test-cluster --region us-west-1
```

- Check on the status of the cluster
```bash
pcluster describe-cluster -n test-cluster
```
Example output:
```json
{
  "creationTime": "2023-02-22T14:08:26.432Z",
  "version": "3.5.0",
  "clusterConfiguration": {
    "url": "https://parallelcluster-24f90b78ae65a281-v1-do-not-delete.s3.amazonaws.com/parallelcluster/3.5.0/clusters/test-cluster-1b9gc9jsem13gus0/configs/cluster-config.yaml?versionId=i0Fi975uuMtBQE3fHrjxPvjBPPm6PsGO&AWSAccessKeyId=AKIA3D436RBNX6J2SLWM&Signature=JbFqM8YHxz92Ib2GeSpodZRy8po%3D&Expires=1677078556"
  },
  "tags": [
    {
      "value": "3.5.0",
      "key": "parallelcluster:version"
    },
    {
      "value": "test-cluster",
      "key": "parallelcluster:cluster-name"
    }
  ],
  "cloudFormationStackStatus": "CREATE_IN_PROGRESS",
  "clusterName": "test-cluster",
  "computeFleetStatus": "UNKNOWN",
  "cloudformationStackArn": "arn:aws:cloudformation:us-west-1:764294367323:stack/test-cluster/5ff61f60-b2ba-11ed-8686-0259999f8571",
  "lastUpdatedTime": "2023-02-22T14:08:26.432Z",
  "region": "us-west-1",
  "clusterStatus": "CREATE_IN_PROGRESS",
  "scheduler": {
    "type": "slurm"
  }
}

```

The cluster creation takes approximately 10 minutes. To get the cluster status you can use `jq`:

```bash
pcluster describe-cluster -n test-cluster | jq .clusterStatus
"CREATE_IN_PROGRESS"
```

or
```bash
 watch -n 10 'pcluster describe-cluster -n test-cluster | jq .clusterStatus'
```

Once the cluster is created the status will be `CREATE_COMPLETE`. Now test the cluster:

- Log in to the head node
```bash
pcluster ssh -n test-cluster
```

- Submit a simple test job:
```bash
sbatch << EOF
#!/usr/bin/env bash
echo "Testing cluster"
EOF
```

- Monitor your job:
```bash
squeue

             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2     small   sbatch ec2-user CF       0:05      1 small-dy-optimal-1

```

- Testing snakemake on the cluster:
```bash
sbatch << EOF
#!/usr/bin/env bash
cat ~/.bashrc
source ~/.bashrc
conda activate arima-py
/shared/AWS_cluster/src/scripts/run_snakemake.sh -s /shared/AWS_cluster/src/snakemake/hello_world.smk -o . -p /shared/singularity
EOF
```

- Cluster cleanup
```bash
pcluster delete-cluster -n test-cluster
```

By default the cluster storage retention policy is set to delete the volume mounted on
`/shared` when the cluster is deleted. Be sure to save any wanted data before deleting the cluster

[fulcrum-genomics-link]: https://www.fulcrumgenomics.com
[conda-link]: https://docs.conda.io/projects/conda/en/latest/user-guide/install/

