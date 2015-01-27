package org.linaro.gparser;

/**
 * Gparser MainActivity
 * Created by Chase Qi(chase.qi@linaro.org) on 1/26/15.
 */

import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;


public class MainActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ListView listView = (ListView) findViewById(R.id.listView1);

        List<TestResult> ResultList = null;

        try {
            XMLPullParserHandler parser = new XMLPullParserHandler();
            FileInputStream is = openFileInput("TestResults.xml");
            ResultList = parser.parse(is);

            FileOutputStream fos = openFileOutput("ParsedTestResult.txt", MODE_WORLD_READABLE);

            for(int i = 0; i < ResultList.size(); i++) {
                fos.write(ResultList.get(i).toString().getBytes());
                fos.write("\n".getBytes());
            }
            fos.close();

            ArrayAdapter<TestResult> adapter =new ArrayAdapter<TestResult>
                    (this,android.R.layout.simple_list_item_1, ResultList);
            listView.setAdapter(adapter);

        } catch (IOException e) {e.printStackTrace();}

    }
}