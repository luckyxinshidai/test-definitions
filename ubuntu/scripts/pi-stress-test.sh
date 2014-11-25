#!/bin/sh 

DURATION=$1
GROUP=$2
MLOCKALL=$3
RR=$4
LogFile="pi_stress.log"

OPTIONS="--duration $DURATION"

if [ "$GROUP" != "default" ]; then
    OPTIONS="$OPTIONS --groups $GROUP"
fi

if [ "$MLOCKALL" = "true" ]; then 
    OPTIONS="$OPTIONS --mlockall"
fi

if [ "$RR" != "false" ]; then
    OPTIONS="$OPTIONS --rr"
fi

# ignore the terminated signal from pi_stress when test failed.
trap '' SIGTERM > /dev/null 2>&1

# run pi_stress test
echo "========"
echo "Running pi_stress with options: $OPTIONS"
pi_stress $OPTIONS  > $LogFile 2>&1 

if [ $? -eq 0 ]; then
    echo "pi_stress test finished successfully"
    grep "Total inversion performed" $LogFile
    lava-test-case pi-stress-test --result pass
else
    grep ERROR $LogFile
    lava-test-case pi-stress-test --result fail
fi

