#!/bin/sh

for bus in `ls /dev/bus/usb`; do
    for device in `ls /dev/bus/usb/$bus`; do
        echo "==================="
        echo "Bus $bus, device $device"
        lsusb -D /dev/bus/usb/$bus/$device
    done
done
