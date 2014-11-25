#!/bin/sh 

DURATION=$1
GROUP=$2
MLOCKALL=$3
RR=$4
LogFile="pistress.log"

OPTIONS="--duration $DURATION"

if [ "$GROUP" != "default" ]; then
    OPTIONS="$OPTIONS --groups $GROUP"
fi

if [ "$MLOCKALL" == "true" ]; then 
    OPTIONS="$OPTIONS --mlockall"
fi

if [ "$RR" != "false" ]; then
    OPTIONS="$OPTIONS --rr"
fi

echo "Running pi_stress with options: $OPTIONS"

# ignore the terminated signal from pi_stress when test failed.
trap '' SIGTERM

# run pi_stress test
echo "========"
echo "Running pi_stress with options: $OPTIONS"
pi_stress $OPTIONS  > $LogFile 2>&1 

if [ $? -eq 0 ]; then
    grep "Total inversion performed" $LogFile
    lava-test-case pi-stress-test --result pass
else
    grep ERROR $LogFile
    lava-test-case pi-stress-test --result fail
fi

