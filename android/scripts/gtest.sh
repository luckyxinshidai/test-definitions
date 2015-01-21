#!/system/bin/sh
set -e
set -x

TESTS=$1

for i in $TESTS; do
    DIR="/data/nativetest"

    # Detect file attribute
    if [ -e $DIR/$i ]; then
        test -d $DIR/$i && DIR="$DIR/$i"
        chmod 755 $DIR/$i
    else
        echo "$i test NOT found."
        echo "lava-test-case $i --result fail"
        continue
    fi

    # Run test 
    chmod 755 $DIR/$i
    $DIR/$i --gtest_output="xml:$i.xml"
    grep "<testsuite name=" $i.xml | awk -F '"' '{print $2,$4,$6}' > $i.xml.parsed
    while read line; do
        array=($line)
        if [ ${array[2]} -eq 0 ]; then
            echo "lava-test-case ${array[0]} --result pass"
        else
            echo "lava-test-case ${array[0]} --result fail"
        fi
    done < $i.xml.parsed
done
