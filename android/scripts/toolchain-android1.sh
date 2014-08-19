#!/bin/sh
#
# Device Tree test cases for Linaro Android
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
# Author: Botao Sun <botao.sun@linaro.org>

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

    if [ ! -f /proc/version ]; then
        fail_test "Unable to find /proc/version"
        return 1
    fi

    version=`grep "Linaro GCC" /proc/version`                        
    if [ -z "$version" ]; then                                   
        fail_test "Empty toolchain description at /proc/version"
        exit 1                                               
    fi                                                             
                                                                   
    echo "Content of /proc/version: $version"

    pass_test
}

# run the tests
test_toolchain_not_empty

# clean exit so lava-test can trust the results
exit 0
