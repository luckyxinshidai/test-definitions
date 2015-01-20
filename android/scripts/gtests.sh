#!/system/bin/sh

TESTS=$1

for i in $TESTS; do
    chmod 755 /data/nativetest/$i
    /data/nativetest/$i --gtest_output="xml:$i.xml"
    grep "<testsuite name=" $i.xml | awk -F '"' '{print $2, $4, $6}' > $i.xml.parsed
    while read line; do
        array=($line)
        if [ ${array[2]} -eq 0 ]; then
            # echo will be removed after local debug.
            echo "lava-test-case ${array[0]} --result pass"
        else
            echo "lava-test-case ${array[0]} --result fail"
        fi
    done < $i.xml.parsed
done
