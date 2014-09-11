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

# Test case definitions
toolchain(){
    echo "Content of /proc/version:"
    echo `cat /proc/version`
    gcc=`grep "Linaro GCC" /proc/version`
    if [ -z "$gcc" ]
    then
        echo "toolchain:" "fail" "gcc not exist"
        return 1
    else
        measurement=`awk '{print substr($5,2,4),$6,$7,$8,$9,$11,$12;}' /proc/version`
        echo "toolchain:" "pass" "$measurement"
    fi
}

# run the test
toolchain

# clean exit so lava-test can trust the results
exit 0
