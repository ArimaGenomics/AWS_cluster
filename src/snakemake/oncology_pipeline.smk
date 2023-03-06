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

log_file: Path = log_dir / "oncology_pipeline.log"
log_file.touch(exist_ok=True)

singularity_image = "docker://arimaxiang/arima_oncology:0.4"

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
        expand("{sample}.oncology.sentinel", sample=samples)

rule run_oncology_pipeline:
    input:
        read1 = S3.remote(expand(input_bucket + "{sample}_R1.fastq.gz", sample=samples)),
        read2 = S3.remote(expand(input_bucket + "{sample}_R2.fastq.gz", sample=samples))
    output:
        txt = "{sample}.oncology.sentinel"
    params:
        sample = "{sample}"
    log:
        "logs/{sample}_run_oncology_pipeline.log"
    singularity: singularity_image
    benchmark:
        "benchmarks/{sample}_run_oncology_pipeline.txt"
    shell:
        """
        # RUN COMMAND GOES HERE
        touch {params.sample}.oncology.sentinel
        &> {log}
        """

rule upload_to_s3:
    input:
        oncology_sentinel = expand("{sample}.oncology.sentinel", sample=samples)
    output:
        done = "s3.transfer.done"
    params:
        output_bucket = output_bucket
    log:
        "logs/upload_to_s3.log"
    shell:
        """
            (aws s3 sync . {params.output_bucket} && \
                touch s3.transfer.done ) &> {log}
        """