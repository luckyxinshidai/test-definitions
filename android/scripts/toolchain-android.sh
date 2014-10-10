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

## Test case definitions
# Check if toolchain version not empty
toolchain-not-empty() {
    echo -e "\n================"
    echo "Check if toolchain version not empty"
    echo "Content of /proc/version:"
    echo `cat /proc/version`
    version=`grep "Linaro GCC" /proc/version`
    if [ -z "$version" ]
    then
        echo "toolchain-not-empty:" "fail" "0"
        return 1
    else
        echo "toolchain-not-empty:" "pass" "0"
    fi
}

# Print GCC version in result bundle
gcc-version() {
    echo -e "\n================"
    echo "Print GCC version"
    GCC=`awk '{print $7;}' /proc/version`
    ReleaseDate=`awk '{print $8;}' /proc/version`
    GCCVersion=$GCC-$ReleaseDate
    if [ -z "$GCCVersion" ]
    then
        echo "gcc-version:" "fail" "0"
        return 1
    else
        echo "gcc-version:" "pass" "$GCCVersion"
    fi
}

# Print Linaro GCC version in result bundle
linaro-gcc-version() {
    echo -e "\n================"
    echo "Print Linaro GCC version"
    LinaroGCC=`awk '{print substr($12,1,11)}' /proc/version`
    if [ -z "$LinaroGCC" ]
    then
        echo "linaro-gcc-version:" "fail" "0"
        return 1
    else
        echo "linaro-gcc-version:" "pass" "$LinaroGCC"
    fi
}

# run the test
toolchain-not-empty
gcc-version
linaro-gcc-version

# clean exit so lava-test can trust the results
exit 0
