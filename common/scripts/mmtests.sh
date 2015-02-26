#!/bin/sh
set -e
set -x

TESTS=$1
KernelVersion=`uname -r`
DIR=`pwd`

# Download tests directly, rather than use the customized mirror.
sed -i '/WEBROOT/s/^/#/' $DIR/shellpacks/common-config.sh

# Result parsing
result_parse(){
    local TEST_ID=$1
    case $TEST_ID in
        dd|dd-tmpfs|ddsync)
            if [ -z `grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/mmtests.log` ]; then
                lava-test-case $TEST_ID --result fail
            else
                units=`grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/dd.30 | awk '{print $9}'`
                # Get the min, max and mean scores of the 30 iterations
                grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/mmtests.log | awk '{print $8}' > $DIR/$TEST_ID-data.txt
                eval `awk '{if(min=="") {min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} \
                      END {print "mean="total/count, "min="min, "max="max}' $DIR/$TEST_ID-data.txt`
                lava-test-case $TEST_ID-min --result pass --measurement $min --units $units
                lava-test-case $TEST_ID-max --result pass --measurement $max --units $units
                lava-test-case $TEST_ID-mean --result pass --measurement $mean --units $units
            fi
            ;;
        ku-latency)
            if [ -z `grep "Average.*us" $DIR/work/log/ku_latency-$KernelVersion/noprofile/ku-latency.log` ]; then
                lava-test-case $TEST_ID --result fail
            else
               # Use the final total average value as measurement
               TotalAverage=`grep "Total Average.*us" $DIR/work/log/ku_latency-$KernelVersion/noprofile/ku-latency.log \
                             | tail -1 | awk '{print $6}'`
               # Use the final rolling average value as measurement
               RollingAverage=`grep "Rolling Average.*us" $DIR/work/log/ku_latency-$KernelVersion/noprofile/ku-latency.log \
                               | tail -1 | awk '{print $6}'`
               lava-test-case $TEST_ID-total-average --result pass --measurement $TotalAverage --units us
               lava-test-case $TEST_ID-rolling-average --result pass --measurement $RollingAverage --units us
            fi
            ;;
    esac
}

## Run tests
for SUB_TEST in $TESTS; do
    $DIR/run-mmtests.sh --no-monitor --config configs/config-global-dhp__$SUB_TEST $KernelVersion
    if [ $? -ne 0 ]; then
        lava-test-case $SUB_TEST --result fail
    else
        result_parse $SUB_TEST
    fi
    rm -rf $DIR/work/testdisk/tmp
done
