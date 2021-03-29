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
export CMAKE_PREFIX_PATH=$HOME/miniconda3/envs/emacs-ide/lib:$CMAKE_PREFIX_PATH
CC="$HOME/miniconda3/envs/emacs-ide/bin/clang" CXX="$HOME/miniconda3/envs/emacs-ide/bin/clang++" cmake -G Ninja -S sourcecode -B clang-build -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_MODULE_PATH="$DBT_ROOT/cmake" # -DCMAKE_TOOLCHAIN_FILE="$testrel/cross-linux.cmake"
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
popd

