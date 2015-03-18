#!/bin/sh
#
# mmtests test case for Linux Linaro Ubuntu.
#
# Copyright (C) 2012 - 2014, Linaro Limited.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Author: Chase Qi <chase.qi@linaro.org>
#         Milosz Wasilewski <milosz.wasilewski@linaro.org>
#         Naresh Kamboju <naresh.kamboju@linaro.org>
#
TESTS=$1
KernelVersion=`uname -r`
DIR=`pwd`

# Download tests directly, rather than use the customized mirror.
sed -i '/WEBROOT/s/^/#/' $DIR/shellpacks/common-config.sh

# Result parser
result_parser(){
    local TEST_ID=$1
    case $TEST_ID in
        dd|dd-tmpfs|ddsync)
            if [ -z "`grep "loopdd fine" $DIR/work/log/loopdd-$KernelVersion/noprofile/mmtests.log`" ]; then
                lava-test-case $TEST_ID --result fail
            else
                dd_units=`grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/mmtests.log | tail -1 | awk '{print $9}'`
                # Get the min, max and mean scores of the 30 iterations
                grep copied $DIR/work/log/loopdd-$KernelVersion/noprofile/mmtests.log | awk '{print $8}' > $DIR/$TEST_ID-data.txt
                eval `awk '{if(min=="") {min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} \
                      END {print "mean="total/count, "min="min, "max="max}' $DIR/$TEST_ID-data.txt`
                lava-test-case $TEST_ID-min --result pass --measurement $min --units $dd_units
                lava-test-case $TEST_ID-max --result pass --measurement $max --units $dd_units
                lava-test-case $TEST_ID-mean --result pass --measurement $mean --units $dd_units
            fi
            if [ "$TEST_ID" = "dd-tmpfs" ]; then
                umount $DIR/work/testdisk
            fi
            ;;
        ku-latency)
            if [ -z "`grep "ku_latency fine" $DIR/work/log/ku_latency-$KernelVersion/noprofile/mmtests.log`" ]; then
                lava-test-case $TEST_ID --result fail
            else
               # Use the final total average value as measurement
               ku_total_average=`grep "Total Average.*us" $DIR/work/log/ku_latency-$KernelVersion/noprofile/ku-latency.log \
                                 | tail -1 | awk '{print $6}'`
               # Use the final rolling average value as measurement
               ku_rolling_average=`grep "Rolling Average.*us" $DIR/work/log/ku_latency-$KernelVersion/noprofile/ku-latency.log \
                                   | tail -1 | awk '{print $6}'`
               lava-test-case $TEST_ID-total-average --result pass --measurement $ku_total_average --units us
               lava-test-case $TEST_ID-rolling-average --result pass --measurement $ku_rolling_average --units us
            fi
            ;;
        libmicro)
            if [ -z "`grep "libmicro fine" $DIR/work/log/libmicro-$KernelVersion/noprofile/mmtests.log`" ]; then
                lava-test-case $TEST_ID --result fail
            else
                for i in `ls $DIR/work/log/libmicro-$KernelVersion/noprofile/memset*`; do
                    # Get test name and usecs/call value in the 3th line of each test log.
                    libmicro_test_name=`sed -n 3p $i | awk '{print $1}'`
                    libmicro_test_result=`sed -n 3p $i | awk '{print $4}'`
                    lava-test-case $TEST_ID-$libmicro_test_name --result pass --measurement $libmicro_test_result --units usecs/call
                done
            fi
            ;;
        preaddd)
            if [ -z "`grep "preaddd fine" $DIR/work/log/preaddd-$KernelVersion/noprofile/mmtests.log`" ]; then
                lava-test-case $TEST_ID --result fail
            else
                preaddd_units=`grep copied $DIR/work/log/preaddd-$KernelVersion/noprofile/mmtests.log | tail -1 | awk '{print $9}'`
                # Get the min, max and mean scores of the 8 iterations
                grep copied $DIR/work/log/preaddd-$KernelVersion/noprofile/mmtests.log | tail -8 | awk '{print $8}' > $DIR/$TEST_ID-data.txt
                eval `awk '{if(min=="") {min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} \
                      END {print "mean="total/count, "min="min, "max="max}' $DIR/$TEST_ID-data.txt`
                lava-test-case $TEST_ID-min --result pass --measurement $min --units $preaddd_units
                lava-test-case $TEST_ID-max --result pass --measurement $max --units $preaddd_units
                lava-test-case $TEST_ID-mean --result pass --measurement $mean --units $preaddd_units
            fi
            ;;
        vmscale)
            if [ -z "`grep "vmscale fine" $DIR/work/log/vmscale-$KernelVersion/noprofile/mmtests.log`" ]; then
                lava-test-case $TEST_ID --result fail
            else
                vmscale_units=`grep copied $DIR/work/log/vmscale-$KernelVersion/noprofile/lru-file-ddspread.log | tail -1 | awk '{print $9}'`
                # Get the min, max and mean scores of all iterations, the number of iterations equal to the number of processors.
                grep copied $DIR/work/log/vmscale-$KernelVersion/noprofile/lru-file-ddspread.log | awk '{print $8}' > $DIR/$TEST_ID-data.txt
                eval `awk '{if(min=="") {min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} \
                      END {print "mean="total/count, "min="min, "max="max}' $DIR/$TEST_ID-data.txt`
                lava-test-case $TEST_ID-ddspread-min --result pass --measurement $min --units $vmscale_units
                lava-test-case $TEST_ID-ddspread-max --result pass --measurement $max --units $vmscale_units
                lava-test-case $TEST_ID-ddspread-mean --result pass --measurement $mean --units $vmscale_units
            fi
            ;;
    esac
}

## Run tests
for SUB_TEST in $TESTS; do
    rm -rf $DIR/work/testdisk/tmp
    $DIR/run-mmtests.sh --no-monitor --config $DIR/configs/config-global-dhp__$SUB_TEST $KernelVersion
    if [ $? -ne 0 ]; then
        lava-test-case $SUB_TEST --result fail
    else
        result_parser $SUB_TEST
    fi
done
