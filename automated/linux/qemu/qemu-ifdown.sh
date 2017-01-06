#!/bin/bash
switch=br0
if [ -n "$1"  ]; then
	#rlease tap interface from bridge
	brctl delif ${switch} $1
	#shutdown the tap interface
	ip link set $1 down
	#delete the specified interface
	ip tuntap del mode tap $1
	exit 0
else
	echo "error: no interface specified"
	exit 1
fi
