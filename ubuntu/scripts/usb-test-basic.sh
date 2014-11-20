#!/bin/sh
# generate test result with lava-test-case
test_result(){
if [ $? -eq 0 ]; then
    lava-test-case $1 --result pass
else
    lava-test-case $1 --result fail
fi
}

# get the usb devices/hubs list
echo "========"
lsusb
test_result list-all-usb-devices

## examine all usb devices/hubs
if [ -d /dev/bus/usb/ ]; then
    for bus in `ls /dev/bus/usb/`; do
        for device in `ls /dev/bus/usb/$bus/`; do
            echo "========"
            echo "Bus $bus, device $device"
            lsusb -D /dev/bus/usb/$bus/$device
            status=$?

            if [ $status -ne 0 ]; then
                echo "Bus$bus-Device$device examination failed"
                break 2
            fi

        done
    done

    if [ $status -eq 0 ]; then
        lava-test-case examine-all-usb-devices --result pass
    else
        lava-test-case examine-all-usb-devices --result fail
    fi

else
    echo "/dev/bus/usb/ not exists"
    lava-test-case examine-all-usb-devices --result fail
fi

# print supported usb protocols
echo "========"
if [ -z "`lsusb -v | grep -i bcdusb`" ]
then
    lava-test-case print-supported-speeds --result fail
else
    lsusb -v | grep -i bcdusb | sort | uniq
    test_result print-supported-speeds
fi

# print supported speeds
echo "========"
lsusb -t
test_result print-supported-speeds

# clean exit so lava-test can trust the results
exit 0