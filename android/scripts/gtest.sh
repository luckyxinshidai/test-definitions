#!/system/bin/sh
set -e
set -x

TESTS=$1

for i in $TESTS; do
    # Detect file attribute.
    DIR="/data/nativetest"
    if [ -e $DIR/$i ]; then
        test -d $DIR/$i && DIR="$DIR/$i"
        chmod 755 $DIR/$i
    else
        echo "$i test NOT found."
        lava-test-case $i --result fail
        continue
    fi

    # Run test.
    chmod 755 $DIR/$i
    # Nonzero exit code will terminate test script, use "||true" as work around.
    $DIR/$i --gtest_output="xml:$i.xml" || true
    if [ -f $i.xml ]; then
        echo "Generated XML report successfullu."
    else
        echo "XML report NOT found."
        lava-test-case $i --result fail
        continue
    fi

    # Parse test result.
    grep "<testsuite name=" $i.xml | awk -F '"' '{print $2,$6}' > $i.xml.parsed
    if [ $? -ne 0 ]; then
        echo "Valid test result NOT found"
        lava-test-case $i --result fail
        continue
    fi

    while read line; do
            TestCaseID=`echo $line | awk '{print $1}'`
            echo $TestCaseID
            Failures=`echo $line | awk '{print $2}'`
            echo $Failures

            if [ $Failures -eq 0 ]; then
                lava-test-case $TestCaseID --result pass
            else
                lava-test-case $TestCaseID --result fail
            fi
    done < $i.xml.parsed
done
