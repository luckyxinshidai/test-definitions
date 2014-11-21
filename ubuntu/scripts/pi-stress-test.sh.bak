#!/bin/bash 

DURATION=$1

# ignore the SIGTERM sign from pi_stress when test failed.
trap '' SIGTERM

pi_stress --mlockall --duration $DURATION  > pi_stress_test.log 2>&1 

if [ $? -eq 0 ]; then
    lava-test-case pi-stress-test --result pass --measurement=0 --units=groups
else
    if [ -n "`grep deadlocked pi_stress_test.log`" ]; then
        grep "ERROR\|deadlocked" pi_stress_test.log
        num_groups=`grep deadlocked pi_stress_test.log | wc -l`
        lava-test-case pi-stress-test --result fail --measurement=$num_groups --units=groups
    else
        grep ERROR pi_stress_test.log
        lava-test-case pi-stress-test --result fail
    fi
fi

lava-test-run-attach pi_stress_test.log text/plain

