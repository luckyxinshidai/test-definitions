package org.linaro.gtestparser;

/**
 * Data object that holds all of information about test results.
 * Created by Chase Qi(chase.qi@linaro.org) on 1/26/15.
 */
public class TestResult {

    private String testsuite = "empty";
    private String testcase = "empty";
    private String result = "pass";

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

    @Override
    public String toString() {
        return testsuite + "." + testcase + ":" + "  " + result;
    }
}