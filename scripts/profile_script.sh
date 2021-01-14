#!/bin/bash


if [ -d perf ]; then
    echo perf directory already exists. Sometimes this makes things go wrong
    echo Delete it and rerun
    exit 1
else
    mkdir perf
fi

# Set this variable to the location where you installed perftools
swdir="/home/rodrigues/dune/daq/appfwk-v2.0/testrel/install"

if [ -z "$swdir" ]; then
    echo "Edit $(basename $0) and set \$swdir to the location where you installed perftools"
    exit 1
fi

starttime=`date '+%s'`
CPUPROFILE=perf/cprof.out CPUPROFILESIGNAL=12 LD_PRELOAD="${swdir}/lib/libunwind.so ${swdir}/lib/libprofiler.so"  $@
LD_PRELOAD=""
endtime=`date '+%s'`
echo real time $(( endtime - starttime )) seconds

# For some reason the system `nm` barfs on libfolly.so, so we mangle the PATH to get the newer conda `nm`
export PATH=$HOME/miniconda3/bin:$PATH
$swdir/bin/pprof --pdf  `which $1` perf/cprof.out > perf/cprof.pdf
