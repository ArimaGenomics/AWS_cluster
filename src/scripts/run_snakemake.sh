#!/usr/bin/env bash
set -x
usage() { 
    local err=${1:-""};
    cat << EOF >&2;
Usage: $0 [options] 

Required:
    -s FILE   Input snakefile
    -o DIR    Output directory

Optional:
    -c FILE   Snakemake configuration file
    -n        Run snakemake in dry run mode
EOF
    echo -e "\n$err" >&2;
    exit 1;
}

dry_run=""

while getopts "s:o:c:p:nh" flag; do
    case "${flag}" in
        s) snakefile=${OPTARG};;
        o) out_dir=${OPTARG};;
        c) config_file=${OPTARG};;
        p) singularity_prefix=${OPTARG};;
        n) dry_run="-n";;
        *) usage;;
    esac
done
shift $((OPTIND-1))

extra_args=""
if [ -z "${snakefile}" ]; then
    usage "Missing required parameter -s";
fi
if [ -z "${singularity_prefix}" ]; then
    usage "Missing required parameter -p";
fi
if [ -z "${out_dir}" ]; then
    usage "Missing required parameter -o";
fi
if [ -n "${config_file}" ]; then
    extra_args="--configfile $config_file";
fi


source "$(dirname "$0")"/common.sh
cores=$(find_core_limit)
mem_gb=$(find_mem_limit_gb)
log "Number of cores: $cores"
log "Memory limit: $mem_gb GB"

# Run Snakemake pipeline
set -euo pipefail

# shellcheck disable=SC2086
snakemake \
  --debug \
  --verbose \
  --printshellcmds \
  --reason \
  --nocolor \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-prefix "$singularity_prefix" \
  --keep-incomplete \
  --jobs 1 \
  --resources "mem_gb=$mem_gb" \
  --snakefile "$snakefile" \
  --directory "$out_dir" \
  $dry_run \
  $extra_args;


log "All done!"
