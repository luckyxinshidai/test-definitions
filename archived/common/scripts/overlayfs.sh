#!/bin/sh

WD=$(pwd)
UnionmountPath=$(readlink -f unionmount-testsuite)
if [ -f /usr/bin/python3 ]; then
    PYTHON='python3'
else
    PYTHON='python2'
fi
PYTHON --version

TESTS="open-plain \
open-trunc \
open-creat \
open-creat-trunc \
open-creat-excl \
open-creat-excl-trunc \
noent-plain \
noent-trunc \
noent-creat \
noent-creat-trunc \
noent-creat-excl \
noent-creat-excl-trunc \
sym1-plain \
sym1-trunc \
sym1-creat \
sym1-creat-excl \
sym2-plain \
sym2-trunc \
sym2-creat \
sym2-creat-excl \
symx-plain \
symx-trunc \
symx-creat \
symx-creat-excl \
symx-creat-trunc \
truncate \
dir-open \
dir-weird-open \
dir-open-dir \
dir-weird-open-dir \
dir-sym1-open \
dir-sym1-weird-open \
dir-sym2-open \
dir-sym2-weird-open \
readlink \
mkdir \
rmdir \
hard-link \
hard-link-dir \
hard-link-sym \
unlink \
rename-file \
rename-empty-dir \
rename-new-dir \
rename-pop-dir \
rename-new-pop-dir \
rename-move-dir \
rename-mass \
rename-mass-2 \
rename-mass-3 \
rename-mass-4 \
rename-mass-5 \
rename-mass-dir \
rename-mass-sym \
impermissible"

for TEST in $TESTS; do
    for TS in 0 1; do
        $python $UnionmountPath/run --ov --ts=$TS $TEST
        if [ $? -eq 0 ]; then
            echo "lava-test-case $TEST-ts-$TS --result pass"
        else
            echo "lava-test-case $TEST-ts-$TS --result fail"
        fi
    done
done
