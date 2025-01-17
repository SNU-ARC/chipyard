#!/bin/bash

# check to see that submodule commits are present on the master branch

# turn echo on and error on earliest command
set -ex

# get shared variables
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
source $SCRIPT_DIR/defaults.sh

# enter bhd repo
cd $LOCAL_CHIPYARD_DIR

# ignore the private vlsi submodules
git config submodule.vlsi/hammer-cadence-plugins.update none
git config submodule.vlsi/hammer-mentor-plugins.update none
git config submodule.vlsi/hammer-synopsys-plugins.update none

all_names=()


search_submodule() {
    echo "Running check on submodule $submodule in $dir"
    # Initialize submodule and get the hashes
    git submodule update --init $dir/$submodule
    git -C $dir/$submodule fetch --unshallow

    status=$(git submodule status)
    hash=$(echo "$status" | grep "$dir.*$submodule " | awk '{print$1}' | grep -o "[[:alnum:]]*")
    for branch in "${branches[@]}"
    do
        echo "Searching for $hash in origin/$branch of $submodule"
        (git -C $dir/$submodule branch -r --contains "$hash" | grep "origin/$branch") && true # needs init'ed submodules
        if [ $? -eq 0 ]
        then
            all_names+=("$dir/$submodule $hash 0")
            return
        fi
    done
    all_names+=("$dir/$submodule $hash 1")
    return
}

search () {
    for submodule in "${submodules[@]}"
    do
        search_submodule
    done
}

submodules=("cva6" "boom" "ibex" "gemmini" "hwacha" "icenet" "nvdla" "rocket-chip" "sha3" "sifive-blocks" "sifive-cache" "testchipip" "riscv-sodor")
dir="generators"
branches=("master" "main" "dev")
search

submodules=("riscv-gnu-toolchain" "riscv-isa-sim" "riscv-pk" "riscv-tests")
dir="toolchains/esp-tools"
branches=("master")
search


submodules=("riscv-gnu-toolchain" "riscv-isa-sim" "riscv-pk" "riscv-tests")
dir="toolchains/riscv-tools"
branches=("master")
search

# riscv-openocd doesn't use its master branch
submodules=("riscv-openocd")
dir="toolchains/riscv-tools"
branches=("riscv")
search

submodules=("qemu" "libgloss")
dir="toolchains"
branches=("master")
search

submodules=("coremark" "firemarshal" "nvdla-workload" "spec2017")
dir="software"
branches=("master" "dev")
search

submodules=("DRAMSim2" "axe" "barstools" "chisel-testers" "dsptools" "rocket-dsp-utils" "torture")
dir="tools"
branches=("master" "dev")
search

submodules=("dromajo-src")
dir="tools/dromajo"
branches=("master")
search

submodules=("firesim")
dir="sims"
branches=("master" "main" "dev")
search

submodules=("hammer")
dir="vlsi"
branches=("master")
search

submodules=("fpga-shells")
dir="fpga"
branches=("master")
search

# turn off verbose printing to make this easier to read
set +x

# print 0's
for str in "${all_names[@]}";
do
    if [ 0 = $(echo "$str" | awk '{print$3}') ]; then
        echo "$str"
    fi
done

echo ""

# check if there was a non-zero return code and print 1's
EXIT=0
for str in "${all_names[@]}";
do
    if [ ! 0 = $(echo "$str" | awk '{print$3}') ]; then
        echo "$str"
        EXIT=1
    fi
done

echo "Done checking all submodules"
exit $EXIT
