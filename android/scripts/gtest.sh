#!/system/bin/sh
set -e
set -x

TESTS=$1
ScriptDIR=`pwd`
FilesDIR="/data/data/org.linaro.gparser/files"

# Download and install gparser.apk
wget http://people.linaro.org/~chase.qi/apks/gparser.apk
chmod -R 777 $ScriptDIR
pm install "$ScriptDIR/gparser.apk" || echo "gparser.apk installation failed"
mkdir $FilesDIR

for i in $TESTS; do
    # Use the last field as test case name, NF refers to the
    # number of fields of the whole string.
    TestCaseName=`echo $i |awk -F '/' '{print $NF}'`
    chmod 755 $i
    # Nonzero exit code will terminate test script, use "||true" as work around.
    $i --gtest_output="xml:$ScriptDIR/$TestCaseName.xml" || true
    if [ -f $ScriptDIR/$TestCaseName.xml ]; then
        echo "Generated XML report successfully."
    else
        echo "$TestCaseName XML report NOT found."
        lava-test-case $TestCaseName --result fail
        continue
    fi

    # Parse test result.
    cp $ScriptDIR/$TestCaseName.xml $FilesDIR/TestResults.xml
    chmod -R 777 $FilesDIR
    am start -n org.linaro.gparser/.MainActivity || echo "Failed to start MainActivity"
    sleep 15
    am force-stop org.linaro.gparser || echo "Failed to stop gparser"
    if [ -f $FilesDIR/ParsedTestResults.txt ]; then
        echo "XML report parsed successfully."
        mv $FilesDIR/ParsedTestResults.txt $ScriptDIR/$TestCaseName.ParsedTestResults.txt
    else
        echo "Failed to parse $TestCaseName test result."
        lava-test-case $TestCaseName --result fail
        continue
    fi

    # Collect test results 
    while read line; do
            TestCaseID=`echo $line | awk '{print $1}'`
            TestResult=`echo $line | awk '{print $2}'`
            
            # Use test case name as prefix.
            lava-test-case $TestCaseName.$TestCaseID --result $TestResult
    done < $ScriptDIR/$TestCaseName.ParsedTestResults.txt
done

# Uninstall gparser
pm uninstall org.linaro.gparser
