package org.bioaster.codira.data.compression;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;

/**
 * Created by pliu on 11/2/17.
 */
public class ZipDirThreadController {

    final static Logger logger = Logger.getLogger(ZipDirThreadController.class);

    public static void main(String[] args){

        ReadConfigFile config= null;
        if(args.length<1||args[0]==null){
            System.out.println("You must enter the config.properties file path as argument");
            logger.error("Miss argument config.properties file path is not provided");
            System.exit(1);
        }
        String configFilePath=args[0];
        try {
            config = new ReadConfigFile(configFilePath);
        } catch (IOException e) {
            logger.error("Can't find compressiong config file. "+e.toString());
            System.exit(1);
        }
        //get the list of dir to be compressed
        String[] dirList = config.getdirList();

        //get thread number
        int threadNum=config.getThreadNum();

        //Configure log4j
        final String LOG_PROPERTIES_FILE = config.getLog4jConfigFilePath();
        PropertyConfigurator.configure(LOG_PROPERTIES_FILE);

        //get output dir
        String outputPath=config.getOutputPath();


        //lauch all the Thread
        lauchThread(threadNum,dirList,outputPath);


    }

    public static void lauchThread(int threadNum, String[] dirList, String outputPath){
        int dirNum=dirList.length;
        int threadCharge=dirNum/threadNum;
        if(threadCharge>=1){
            int startIndex=0;
            for(int i=0;i<threadNum;i++){

                String threadId="thread_"+i;
                int endIndex;
                //last thread takes all the dir still in the list
                if (i+1==threadNum){endIndex=dirNum;}
                else {endIndex=startIndex+threadCharge;}
                //@since 1.6
                String[] thread_dir_list = Arrays.copyOfRange(dirList, startIndex, endIndex);
                ZipDirThread zipDir=new ZipDirThread(threadId,outputPath,thread_dir_list);
                zipDir.start();
                //After operation reset the startIndex
               startIndex=endIndex;
            }
        }
        //
        else {
            logger.error("The thread number is greater than the number of directory which to be compressed, You are wasting your resources");
            System.exit(1);}
    }
}
