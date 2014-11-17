#!/bin/sh

# generate test result
test_result(){
if [ $? -eq 0 ]
then
    echo "$1:" "pass"
else
    echo "$1:" "fail"
fi
}

# get the usb devices/hubs list
echo "========"
lsusb
test_result list-all-usb-devices

# print supported usb protocols
echo "========"
lsusb -v | grep -i bcdusb
test_result print-supported-protocols

# print supported speeds
echo "========"
lsusb -t
test_result print-supported-speeds

# print detailed information of all usb devices/hubs
for bus in `ls /dev/bus/usb`; do
    for device in `ls /dev/bus/usb/$bus`; do
        echo "========"
        echo "Bus $bus, device $device"
        lsusb -D /dev/bus/usb/$bus/$device
    done
done
test_result print-device-information

# clean exit so lava-test can trust the results
exit 0
