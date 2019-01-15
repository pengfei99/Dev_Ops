package org.bioaster.codira.data.compression;

import org.apache.log4j.Logger;

/**
 * Created by pliu on 11/2/17.
 */
public class ZipDirThread implements Runnable {

    final static Logger logger = Logger.getLogger(ZipDirThread.class);

    private Thread thread;
    private String threadId;
    private String outputPath;
    private String[] dirList;

    public ZipDirThread(String threadId, String outputPath, String[] dirList){
        this.threadId=threadId;
        this.outputPath=outputPath;
        this.dirList=dirList;
        logger.info("Compression Thread "+threadId+" has been created");
    }


    public void run() {
        ZipDir zipDir=new ZipDir(threadId);
      for (int i=0;i<dirList.length;i++){
          boolean result=zipDir.compressTargetDir(dirList[i],outputPath);
          if(result) logger.info("Directory "+dirList[i]+" has been compressed successfully");
          else logger.error("Directory "+dirList[i]+" can't be compressed");
      }
      logger.info("Compression Thread "+threadId+" finished" );
    }

    public void start(){
        logger.info("Starting Compression Thread "+threadId);
        if(thread==null){
            thread=new Thread(this,threadId);
            thread.start();
        }
    }
}
