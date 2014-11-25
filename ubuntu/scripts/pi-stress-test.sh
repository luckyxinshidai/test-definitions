#!/bin/bash
#
# pi_stress test cases for Linux Linaro ubuntu
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
#

DURATION=$1
GROUP=$2
MLOCKALL=$3
RR=$4
OPTIONS="--duration $DURATION"
LogFile="pi_stress.log"

if [ "$GROUP" != "default" ]; then
    OPTIONS="$OPTIONS --groups $GROUP"
fi

if [ "$MLOCKALL" = "true" ]; then
    OPTIONS="$OPTIONS --mlockall"
fi

if [ "$RR" != "false" ]; then
    OPTIONS="$OPTIONS --rr"
fi

echo "========"
echo "Running pi_stress test with options: $OPTIONS"
trap '' SIGTERM
pi_stress $OPTIONS > $LogFile 2>&1

if [ $? -eq 0 ]; then
    echo "pi_stress test finished successfully"
    grep "Total inversion performed" $LogFile
    lava-test-case pi-stress-test --result pass
else
    echo "Error occurred, pi_stresss test failed"
    grep ERROR $LogFile
    lava-test-case pi-stress-test --result fail
fi
