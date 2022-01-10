#!/bin/bash

set -euo pipefail

workdir="$1"; shift
version="$1"; shift

if [[ -z "$version" || "$version" =~ ^N2 ]]; then
    #dunedaq_version=dunedaq-v$(echo /cvmfs/dunedaq.opensciencegrid.org/releases/* | sed -e 's,dunedaq-v,,' | sort -n -t . -k 1,1 -k 2,2 -k 3,3)
    dunedaq_version="latest"
else
    dunedaq_version="$version"
fi
echo dunedaq_version is "$dunedaq_version"

if [[ -z "$CONDA_DEFAULT_ENV" ]]; then
    conda deactivate
fi

source /cvmfs/dunedaq.opensciencegrid.org/setup_dunedaq.sh
echo setup_dbt
setup_dbt "$dunedaq_version"
if [[ "$version" =~ ^N2 ]]; then
    # Nightly
    echo dbt-create.sh --clone-pyvenv --nightly "$version" "$workdir"
    dbt-create.sh --clone-pyvenv --nightly "$version" "$workdir"
else
    # Not nightly
    echo dbt-create.sh --clone-pyvenv "$version" "$workdir"
    dbt-create.sh --clone-pyvenv "$version" "$workdir"
fi

cat <<EOF > "$workdir/.dir-locals.el"
((nil . ((projectile-generic-command . "dbt-git-ls-for-projectile.sh")
                                 )))
EOF

cp /cvmfs/dunedaq.opensciencegrid.org/tools/dbt/latest/configs/.clang-format "$workdir/sourcecode/"

pushd "$workdir/sourcecode"
git clone git@github.com:philiprodrigues/daq-utilities
popd

pushd "$workdir"
mkdir rundir
pushd rundir
curl -o frames.bin -O https://cernbox.cern.ch/index.php/s/7qNnuxD8igDOVJT/download
popd
popd

set +u
if [[ -n "$1" ]]; then
    pushd "$workdir/sourcecode"
    while [[ -n "$1" ]]; do
        echo "Cloning package $1"
        git clone "git@github.com:DUNE-DAQ/$1"
        shift
    done
    popd
fi
set -u
