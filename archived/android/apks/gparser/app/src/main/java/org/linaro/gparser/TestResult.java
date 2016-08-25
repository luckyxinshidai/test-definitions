package org.linaro.gparser;

/**
 * Data object that holds all of information about test results.
 * Created by Chase Qi(chase.qi@linaro.org) on 1/26/15.
 */
public class TestResult {

    private String testsuite = "NA";
    private String testcase = "NA";
    private String result = "pass";
    private String time = "0";

    public String getTestSuite() {
        return testsuite;
    }
    public void setTestSuite(String testsuite) {
        this.testsuite = testsuite;
    }
    public String getTestCase() {
        return testcase;
    }
    public void setTestCase(String testcase) {
        this.testcase = testcase;
    }
    public String getResult() {
        return result;
    }
    public void setResult(String result) {
        this.result = result;
    }
    public String getTime() {
        return time;
    }
    public void setTime(String time) {
        this.time = time;
    }

    @Override
    public String toString() {
        return testsuite + "." + testcase + "\t" + result + "\t" + time;
    }
}