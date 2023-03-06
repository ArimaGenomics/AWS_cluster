#!/usr/bin/env bash

###############################################################################
# Script that should be run pre-commit after making any changes to the arimapy
# package / subdirectory.
#
# Runs:
#   Unit tests
#   Linting
#   Type checking
###############################################################################

set -e

failures=""

function banner() {
    echo
    echo "================================================================================"
    echo "$*"
    echo "================================================================================"
    echo
}

#####################################################################
# Takes two parameters, a "name" and a "command". 
# Runs the command and prints out whether it succeeded or failed, and
# also tracks a list of failed steps in $failures.
#####################################################################
function run() {
    local name=$1
    local cmd=$2

    banner "Running $name [$cmd]"
    set +e
    $cmd
    exit_code=$?
    set -e
    
    if [[ $exit_code == 0 ]]; then
        echo Passed $name 
    else
        echo Failed $name [$cmd]
        if [ -z "$failures" ]; then
            failures="$failures $name"
        else
            failures="$failures, $name"
        fi
    fi
}

parent=$(cd "$(dirname $0)" && pwd -P)
root=$(dirname ${parent})/src/python
r_root=$(dirname ${parent} | xargs dirname)/R

if [[ -z ${CONDA_DEFAULT_ENV} ]]; then
    banner "Conda not active. arimapy conda environment must be active."
    exit 1
fi

pushd $root > /dev/null
banner "Executing in conda environment ${CONDA_DEFAULT_ENV} in directory ${root}"
run "Unit Tests"     "pytest -vv -r sx arimapy"
run "Style Checking" "black --line-length 99 --check arimapy"
run "Linting"        "flake8 --config=$parent/flake8.cfg arimapy"
run "Type Checking"  "mypy -p arimapy --config $parent/mypy.ini"
popd > /dev/null

if [ -z "$failures" ]; then
    banner "Precommit Passed"
else
    banner "Precommit Failed with failures in: $failures"
    exit 1
fi

