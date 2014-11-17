#!/bin/sh

# decide test result
print_test_result(){
if [ $? -eq 0 ]
then
    echo "$1" "pass"
else
    echo "$1" "fail"
    exit 1
fi
}

# get the usb devices/hubs list
echo "========"
lsusb
print_test_result list-all-usb-devices

# enumerate all usb devices/hubs
for bus in `ls /dev/bus/usb`; do
    for device in `ls /dev/bus/usb/$bus`; do
        echo "========"
        echo "Bus $bus, device $device"
        lsusb -D /dev/bus/usb/$bus/$device
    done
done

print_test_result print-device-information

# print supported usb protocols
echo "========"
lsusb -v | grep -i bcdusb
print_test_result print-supported-protocols

# print supported speeds
echo "========"
lsusb -t
print_test_result print-supported-speeds

# clean exit so lava-test can trust the results
exit 0 
