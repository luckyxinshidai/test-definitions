package org.linaro.gtestparser;

/**
 * XMLPullParserHandler for XML parsing.
 * Created by Chase Qi(chase.qi@linaro.org) on 1/26/15.
 */

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

public class XMLPullParserHandler {
    private List<TestResult> ResultList= new ArrayList<TestResult>();
    private TestResult testresult;

    public List<TestResult> getTestResults() {
        return ResultList;
    }

    public List<TestResult> parse(FileInputStream is) {
        try {
            // get factory and PullParser
            XmlPullParserFactory factory = XmlPullParserFactory.newInstance();
            factory.setNamespaceAware(true);
            XmlPullParser xpp = factory.newPullParser();

            xpp.setInput(is, null);

            int eventType = xpp.getEventType();
            while (eventType != XmlPullParser.END_DOCUMENT) {
                // get the current tag
                String tagname = xpp.getName();

                // React to different event types appropriately
                switch (eventType) {
                    case XmlPullParser.START_TAG:
                        if (tagname.equalsIgnoreCase("testcase")) {
                            // create a new instance of TestResult
                            testresult = new TestResult();
                            // get the name attribute as testcase name
                            String testcase = xpp.getAttributeValue(0);
                            testresult.setTestCase(testcase);
                            // get the classname attribute as testsuite name
                            String testsuite = xpp.getAttributeValue(3);
                            testresult.setTestSuite(testsuite);
                        }
                        break;

                    case XmlPullParser.END_TAG:
                        if (tagname.equalsIgnoreCase("testcase")) {
                            // if </testcase> then we are done with current test case
                            // add testresult object to list
                            ResultList.add(testresult);
                        }else if (tagname.equalsIgnoreCase("failure")) {
                            // if </failure> set result to fail
                            testresult.setResult("fail");
                        }
                        break;

                    default:
                        break;
                }
                // move on to next iteration
                eventType = xpp.next();
            }

        } catch (XmlPullParserException | IOException e) {e.printStackTrace();}

        return ResultList;
    }
}