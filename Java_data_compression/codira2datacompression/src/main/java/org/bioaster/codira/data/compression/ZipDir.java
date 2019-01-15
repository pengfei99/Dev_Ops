package org.bioaster.codira.data.compression;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Created by pliu on 11/2/17.
 */
public class ZipDir {

    final static Logger logger = Logger.getLogger(ZipDir.class);

    private String threadId;

    public ZipDir(String threadId){
        this.threadId=threadId;
    }


    public boolean compressTargetDir(String targetDirPath,String outputPath){

        boolean result;
        File targetDir=new File(targetDirPath);
        List<File> fileList = this.getAllFileList(targetDir);
        try {
            this.writeZipFile(targetDir,fileList,outputPath);
            result=true;
        } catch (IOException e) {
            logger.error(e.toString());
            result=false;
        }
        return result;
    }


    private List<File> getAllFileList(File targetDir){
        List<File> fileList=new ArrayList<File>();
        this.getAllFiles(targetDir,fileList);
        return fileList;
    }

    /*
    * @INPUT targetDir is the directory to be zipped
    * @INPUT fileList is the list of files to be zipped in the targetDir, it should be empty at start
    * */
    private void getAllFiles(File targetDir, List<File> fileList) {
            File[] files = targetDir.listFiles();
            for (File file : files) {
                fileList.add(file);
                if (file.isDirectory()) {
                    getAllFiles(file, fileList);
                }
            }

    }



    private void writeZipFile(File directoryToZip, List<File> fileList, String outputPath) throws IOException {


            if(outputPath.equalsIgnoreCase("NULL")){
                String dirPath = directoryToZip.getCanonicalPath();
                outputPath=dirPath.substring(0,dirPath.length()-directoryToZip.getName().length()-1);
            }
            String zipFileName=directoryToZip.getName() + ".zip";
            String fullName=outputPath+"/"+zipFileName;

            FileOutputStream fos = new FileOutputStream(fullName);
            ZipOutputStream zos = new ZipOutputStream(fos);

            for (File file : fileList) {
                if (!file.isDirectory()) { // we only zip files, not directories
                    addToZip(directoryToZip, file, zos);
                }
            }

            zos.close();
            fos.close();

    }

    private void addToZip(File directoryToZip, File file, ZipOutputStream zos) throws FileNotFoundException,
            IOException {

        FileInputStream fis = new FileInputStream(file);

        // we want the zipEntry's path to be a relative path that is relative
        // to the directory being zipped, so chop off the rest of the path
        String zipFilePath = file.getCanonicalPath().substring(directoryToZip.getCanonicalPath().length() + 1,
                file.getCanonicalPath().length());
        logger.debug("Thread "+ threadId +" writing '" + zipFilePath + "' to zip file "+ directoryToZip.getName() + ".zip");
        ZipEntry zipEntry = new ZipEntry(zipFilePath);
        zos.putNextEntry(zipEntry);

        byte[] bytes = new byte[2048];
        int length;
        while ((length = fis.read(bytes)) >= 0) {
            zos.write(bytes, 0, length);
        }

        zos.closeEntry();
        fis.close();
    }
}
