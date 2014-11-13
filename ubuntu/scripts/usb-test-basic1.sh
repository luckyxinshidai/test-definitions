#!/bin/sh

# decide test result
test_result(){
if [ $? -eq 0 ]
then
    echo "$1" "pass"
else
    echo "$1" "fail"
    exit 1
fi
}

# print usb device/hub detailed information
device_info(){
lsusb -D /dev/bus/usb/$1/$2
test_result bus$1-device$2-test
}

# enumerate all usb devices/hubs
for bus in `ls /dev/bus/usb`; do
    for device in `ls /dev/bus/usb/$bus`; do
        echo "========"
        device_info $bus $device
    done
done
