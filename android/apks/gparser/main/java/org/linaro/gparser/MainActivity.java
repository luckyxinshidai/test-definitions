package org.linaro.gparser;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;


public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ListView listView = (ListView) findViewById(R.id.listView1);

        List<TestResult> ResultList = null;

        try {
            XMLPullParserHandler parser = new XMLPullParserHandler();

            //Read TestResults.xml from /data/data/org.linaro.gparser/files/
            FileInputStream fis = openFileInput("TestResults.xml");
            ResultList = parser.parse(fis);

            // Save parsed result to /data/data/org.linaro.gparser/files/parsedTestResults.txt
            FileOutputStream fos = openFileOutput("ParsedTestResults.txt", MODE_WORLD_READABLE);
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


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
