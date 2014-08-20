#!/system/bin/sh
#
# toolchain test cases for Linaro Android
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

function fail_test() {
    local reason=$1
    echo "${TEST}: FAIL - ${reason}"
}

function pass_test() {
    echo "${TEST}: PASS"
}

## Test case definitions
# Check if /proc/version and toolchain version not empty
test_toolchain_not_empty() {
    TEST="test_toolchain_not_empty"
    version=`grep "Linaro GCC" /proc/version`

    if [ -z "$version" ]
    then
        fail_test "Empty toolchain description in /proc/version"
        return 1
    else
        echo "Content of /proc/version: $version"
        pass_test
    fi
}

# Check if toolchain version correct
test_toolchain_version_measurement() {
    TEST="test_toolchain_version_measurement"
    LinaroGCC=`awk '{print substr($12,5,7)}' /proc/version`
    BuildYear=`awk '{print $22;}' /proc/version`
    BuildMonth=`awk '{print $18;}' /proc/version`
    case $BuildMonth in
         Jan) BuildMonth=01 ;;
         Feb) BuildMonth=02 ;;
         Mar) BuildMonth=03 ;;
         Apr) BuildMonth=04 ;;
         May) BuildMonth=05 ;;
         Jun) BuildMonth=06 ;;
         Jul) BuildMonth=07 ;;
         Aug) BuildMonth=08 ;;
         Sep) BuildMonth=09 ;;
         Oct) BuildMonth=10 ;;
         Nov) BuildMonth=11 ;;
         Dec) BuildMonth=12 ;;
    esac
    BuildDay=`awk '{print $19;}' /proc/version`

    Measurement=$BuildYear.$BuildMonth

    if [ $BuildDay -ge 16 ]
    then
        if [ "$LinaroGCC" != "$Measurement" ]
        then
           fail_test "Wrong Toolchain version"
           echo "Toolchain $Measurement should be used after the 15th"
           echo "Toolchain used for this image: $LinaroGCC"
           return 1
        fi
    else
        echo "Correct toolchain used, version: $LinaroGCC"
        pass_test
    fi
}

# run the tests
# test_toolchain_not_empty
test_toolchain_version_measurement

# clean exit so lava-test can trust the results
exit 0
