package org.bioaster.codira.data.compression;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Created by pliu on 11/2/17.
 */
public class ReadConfigFile {
    private Properties config= new Properties();
    private InputStream input=null;

    public ReadConfigFile(String configfilePath) throws IOException {
        input=new FileInputStream(configfilePath);
        config.load(input);
    }



    public String getOutputPath(){
        return config.getProperty("outputPath");
    }

    public String[] getdirList(){
        return config.getProperty("dirList").split(";");
    }

    public String getLog4jConfigFilePath() {return config.getProperty("log4jFilePath");}

    public int getThreadNum(){
        String threadNum = config.getProperty("threadNum");
        return Integer.parseInt(threadNum);
    }



    public static void main(String[] args) throws IOException {

    }
}
