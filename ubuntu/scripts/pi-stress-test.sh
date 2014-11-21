#!/bin/sh 

DURATION=$1

# ignore the terminated signal from pi_stress when test failed.
trap '' SIGTERM

# run pi_stress test with customized running time
pi_stress --mlockall --duration $DURATION  > pi_test.log 2>&1 

if [ $? -eq 0 ]; then
    grep "Total inversion performed" pi_test.log
    lava-test-case pi-stress-test --result pass
else
    grep ERROR pi_test.log
    lava-test-case pi-stress-test --result fail
fi

# attach the pi_stress.log file
lava-test-run-attach pi_stress.log
