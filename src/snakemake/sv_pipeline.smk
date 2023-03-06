################################################################################
# Hello World pipeline
################################################################################

from pathlib import Path
from typing import List

from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
from arimapy.pipeline import snakemake_utils

################################################################################
# Utility methods and variables
################################################################################
S3 = S3RemoteProvider()

log_dir: Path = Path("logs")
log_dir.mkdir(exist_ok=True)

log_file: Path = log_dir / "sv_pipeline.log"
log_file.touch(exist_ok=True)

singularity_image = "docker://arimaxiang/arima_sv:1.1"

input_bucket: str = config.get("input_bucket")
output_bucket: str = config.get("output_bucket")

bucket_prefix = input_bucket.replace("s3://", "").strip().strip('/')
samples: List = S3.glob_wildcards(bucket_prefix + "/{sample}_R1.fastq.gz").sample

################################################################################
# Terminal files
################################################################################

all_terminal_files: List[Path] = [Path("s3.transfer.done")]

################################################################################
# Snakemake rules
################################################################################

onerror:
    """Block of code that gets called if the snakemake pipeline exits with an error."""
    snakemake_utils.on_error(snakefile=Path(__file__), config=config, log=log_file )


rule all:
    input:
        all_terminal_files,
        expand("{sample}.sv.sentinel", sample=samples)

rule run_sv_pipeline:
    input:
        read1 = S3.remote(expand(input_bucket + "{sample}_R1.fastq.gz", sample=samples), keep_local=True),
        read2 = S3.remote(expand(input_bucket + "{sample}_R2.fastq.gz", sample=samples), keep_local=True)
    output:
        txt = "{sample}.sv.sentinel"
    params:
        sample = "{sample}"
    log:
        "logs/{sample}_run_sv_pipeline.log"
    singularity: singularity_image
    benchmark:
        "benchmarks/{sample}_run_sv_pipeline.txt"
    shell:
        """
        # RUN COMMAND GOES HERE
        touch {params.sample}.sv.sentinel
        &> {log}
        """

rule upload_to_s3:
    input:
        sv_sentinel = expand("{sample}.sv.sentinel", sample=samples)
    output:
        done = "s3.transfer.done"
    params:
        output_bucket = output_bucket
    log:
        "logs/upload_to_s3.log"
    shell:
        """
            (aws s3 sync --exclude .snakemake/* --exclude *.simg . {params.output_bucket} && \
                touch s3.transfer.done ) &> {log}
        """