package org.linaro.gtestparser;

import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;


public class MainActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        //ListView listView = (ListView) findViewById(R.id.listView1);
        List<TestResult> ResultList = null;

        try {
            XMLPullParserHandler parser = new XMLPullParserHandler();
            FileInputStream is = openFileInput("TestResults.xml");
            ResultList = parser.parse(is);

            FileOutputStream fos = openFileOutput("ParsedTestResults.txt", MODE_WORLD_READABLE);

            for (int i = 0; i < ResultList.size(); i++) {
                fos.write(ResultList.get(i).toString().getBytes());
                fos.write("\n".getBytes());
            }
            fos.close();

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
