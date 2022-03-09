#!/bin/bash

set -eu

if [ "$#" != 1 ]; then
    echo Usage: $(basename $0) path_to_testrel
    exit 1
fi

testrel="$1"

# ${variablename+x} expands to nothing if variable is unset, or "x" if
# it is set
# if [ -z "${CONDA_DEFAULT_ENV+x}" ]; then
#    conda init bash
#    conda activate base
# fi


pushd "$testrel"
export CMAKE_PREFIX_PATH=$HOME/miniconda3/lib:$CMAKE_PREFIX_PATH
CC="$HOME/miniconda3/bin/clang" CXX="$HOME/miniconda3/bin/clang++" cmake -G Ninja -S sourcecode -B clang-build -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_MODULE_PATH="$DBT_ROOT/cmake" # -DCMAKE_TOOLCHAIN_FILE="$testrel/cross-linux.cmake"
cp clang-build/compile_commands.json "$testrel"

# Sadly clang++ needs "-stdlib=libc++" added manually to the command
# line. Don't understand why cmake doesn't know to add it
#
# Also, the futzing with default values for template template parameters that's done in FollyQueue.hpp appears to trigger the issue mentioned in this footnote:
#
# https://clang.llvm.org/cxx_status.html#p0522
#
# (Linked from
# https://stackoverflow.com/questions/48645226/template-template-parameter-and-default-values
# )
#
# To work around it, we add -frelaxed-template-template-args
sed -i -e 's,clang++,clang++ -frelaxed-template-template-args -stdlib=libc++,' "$testrel/compile_commands.json"

# And another thing...
#
# The daq-cmake build relies on #including codegen items from the
# build dir. For this clang build, we use our own clang-build
# directory, so as not to stomp all over the real build directory. But
# we never use this directory for an actual build, so there are no
# codegen items in it. So we munge the -I/path/to/clang-build args to
# point to /path/to/build instead
clang_build_dir=${testrel}/clang-build
build_dir=${testrel}/build
sed -i -e "s,${clang_build_dir},${build_dir},g" "$testrel/compile_commands.json"
#
# Attempt #2 at the same thing: looks like we're getting include
# directories in the compile_commands.json that are relative to the
# build dir
sed -i -e "s,-I\([^/][^[:space:]]\+\),-I${build_dir}/\1,g" "$testrel/compile_commands.json"
popd

