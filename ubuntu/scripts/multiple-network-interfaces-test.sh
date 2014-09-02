#!/bin/bash
#
# Multiple network interfaces test for ubuntu
#
# Copyright (C) 2013, Linaro Limited.
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

# source include/sh-test-lib

GATEWAY=10.0.0.1

# Display all interfaces currently available
echo "All interfaces currently available"
echo "================================="
ifconfig -a

# Correction of ARP flux
address-arp-flux(){
echo -e "\nAddress ARP flux"
echo "==============="
for i in all default $(ls /proc/sys/net/ipv4/conf/ | grep eth)
do
    echo 0 > /proc/sys/net/ipv4/conf/$i/rp_filter
    echo "$i rp_filter: `cat /proc/sys/net/ipv4/conf/$i/rp_filter`"
    echo 1 > /proc/sys/net/ipv4/conf/$i/arp_ignore
    echo "$i arp_ignore: `cat /proc/sys/net/ipv4/conf/$i/arp_ignore`"
    echo 2 > /proc/sys/net/ipv4/conf/$i/arp_announce
    echo "$i arp_announce: `cat /proc/sys/net/ipv4/conf/$i/arp_announce`"
done

if [ $? -ne 0 ]
then
    echo "address-arp-flux:" "fail"
    return 1
else
    echo "address-arp-flux:" "pass"
fi

}

# Interface disable test
interface-disable-test(){
echo -e "\n$i interface disable test"
echo "=========================="
ifconfig $i down

if [ $? -ne 0 ]
then
    echo "$i-interface-disable-test:" "fail"
    return 1
else
    echo "$i-interface-disable-test:" "pass"
fi
sleep 10

}

# Interface enable test
interface-enable-test(){
echo -e "\n$i interface enable test"
echo "========================="
ifconfig $i up

if [ $? -ne 0 ]
then
    echo "$i-interface-enable-test:" "fail"
    return 1
else
    echo "$i-interface-enable-test:" "pass"
fi
sleep 10

}

# IP not empty test
ip-not-empty(){
echo -e "\n$i-ip-not-empty test"
echo "====================="
IP=$(ifconfig $i | grep "inet addr" | awk '{print substr($2,6,10)}')

if [ $? -ne 0 ]
then
    echo "$i have no IP address"
    echo "$i-ip-not-empty:" "fail"
    return 1
else
    echo "$i IP: $IP"
    echo "$i-ip-not-empty:" "pass"
fi

}

# ping test
ping-test(){
echo -e "\n$i ping test"
echo "============="
ping -c 5 -I $i $GATEWAY

if [ $? -ne 0 ]
then
    echo "Ping test through $i failed"
    echo "$i-ping-test:" "fail"
    return 1
else
    echo "$i-ping-test:" "pass"
fi

}

# Packet loss test
packet-loss-test(){
echo -e "\n$i packet loss test"
echo "==================="
packet_loss=`ping -c 5 -I eth0 10.0.0.1 | grep "packet loss" | awk '{print $6;}'`

if [ "$packet_loss" != "0%" ]
then
    echo "Packet loss happened, rate is $packet_loss"
    echo "$i-packet-loss-test:" "fail"
    return 1
else
   echo "Packet loss rate: $packet_loss"
   echo "$i-packet-loss-test:" "pass"
fi

}

# Run the tests
address-arp-flux
for i in $(ls /proc/sys/net/ipv4/conf/ | grep eth)
do
    interface-disable-test
    interface-enable-test
    ip-not-empty
    ping-test
    packet-loss-test
done
    
# clean exit so lava-test can trust the results
exit 0
