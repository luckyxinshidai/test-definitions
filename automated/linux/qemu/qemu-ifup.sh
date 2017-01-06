#!/bin/bash
switch=br0
if [ -n "$1"  ]; then
	#create a tap interface
	ip tuntap add $1 mode tap
	sleep 2
	#start up the tap interface
	ip link set $1 up
	sleep 2
	#add tap interface to the bridge
	brctl addif ${switch} $1
	exit 0
else
	echo "error: no interface specified"
	exit 1
fi
