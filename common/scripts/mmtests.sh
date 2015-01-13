#!/bin/sh
set -e
set -x

TESTS="$1"
KernelVersion=`uname -r`
DIR=`pwd`

# Download tests directly, rather than use the customized mirror.
sed -i '/WEBROOT/s/^/#/' $DIR/shellpacks/common-config.sh

# Result parse
result_parse(){
    local TEST_ID=$1
    case $TEST_ID in
        dd|dd-tmpfs|ddsync)
            if [ -e $DIR/work/log/loopdd-$KernelVersion/noprofile/dd.30 ]; then
                ddloop_speed=`grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/dd.30 |grep copied|awk '{print $8}'`
                lava-test-case $TEST_ID --result pass --measurement $ddloop_speed --units MB/s
            else
                lava-test-case $TEST_ID --result fail
            fi
            ;;
    esac
}

## Run tests
for SUB_TEST in $TESTS; do
    $DIR/run-mmtests.sh --config configs/config-global-dhp__$SUB_TEST $KernelVersion
    if [ $? -ne 0 ]; then
        lava-test-case $SUB_TEST --result fail
    else
        result_parse $SUB_TEST
    fi
done
