#!/bin/sh 

DURATION=$1

# ignore the terminated signal from pi_stress when test failed.
trap '' SIGTERM

# run pi_stress test with customized running time
LogFile=pi_stress.log
pi_stress --mlockall --duration $DURATION  > $LogFile 2>&1 

if [ $? -eq 0 ]; then
    grep "Total inversion performed" $LogFile
    lava-test-case pi-stress-test --result pass
else
    grep ERROR $LogFile
    lava-test-case pi-stress-test --result fail
fi

# attach the log file
lava-test-run-attach $LogFile
