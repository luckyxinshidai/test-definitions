#!/bin/sh
#
# Blogbench is a portable filesystem benchmark.
#
# Copyright (C) 2010 - 2014, Linaro Limited.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Chase Qi <chase.qi@linaro.org>


min_max_mean()
{
    eval `awk '{if(min=="") {min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} \
         END {print "mean="total/count, "min="min, "max="max}' $1`
}

iteration=$1
count=1
mkdir ./bench

while [ $count -le $iteration ]
do
    echo
    echo "Running blogbench iteration $count ..."
    blogbench -d ./bench 2>&1 | tee blogbench_run$count.txt
    if [ $? -eq 0 ]; then
        lava-test-case blogbench-run${count} --result pass
    else
        lava-test-case blogbench-run${count} --result fail
    fi

    # If iteration greater then 3, collect writes and reads scores of all runs.
    if [ $iteration -ge 3 ]; then
        for i in writes reads
        do
            score=$(grep "Final score for $i" blogbench_run${count}.txt | awk '{print $NF}')
            lava-test-case $i-run${count} --result pass --measurement $score --units none
            echo $score >> blogbench_${i}.txt

            # After all iteration finish, calculate min, max and mean value.
            if [ $count -eq $iteration ]; then
                min_max_mean blogbench_${i}.txt
                lava-test-case blogbench-writes-min --result pass --measurement $min --units none
                lava-test-case blogbench-writes-max --result pass --measurement $max --units none
                lava-test-case blogbench-writes-mean --result pass --measurement $mean --units none
            fi
        done
    fi

    count=$(( $count + 1 ))
    rm -rf ./bench/*
done
