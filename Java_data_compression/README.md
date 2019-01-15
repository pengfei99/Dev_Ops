# Multi thread compressor

This project aims to compress large amount data with multi thread


### Prerequisites

This tool only requires java 1.6 or above

```
java 1.6, 1.7, 1.8, 1.9
```

### Supported OS

Windows XP/7/8/10

Linux  

MacOS

### Installing

This tool is already compiled, you don't need to install anything.
Just make sure you have jre.

To do that, you just type java -version

```
java -version

java version "1.8.0_144"
Java(TM) SE Runtime Environment (build 1.8.0_144-b01)
Java HotSpot(TM) 64-Bit Server VM (build 25.144-b01, mixed mode)

```
If you see nothing, you need to install java on your PC.

* [Doc en version](https://java.com/en/download/help/windows_manual_download.xml)
* [Doc fr version](https://www.java.com/fr/download/help/windows_manual_download.xml)

After java installation, you only need to download the compressor executable
* [compressor](https://owncloud.bioaster.org/index.php/s/sidaXUWCjkPi8MW)

## Running the tool

Before you run the tool, you need to adapter two following config files in your environment

### Adapter your config file

`config.properties` is the main config file of the compressor.

`dirList` specifies a list of dirctories which will be compressed, directories need to be separated by ; (e.g. dir1;dir2;dir3)

`outputPath` specifies where you want to put the compressed file, if you set null as argument, it will put the compressed data in the same folder of the source data.

`threadNum` specifies the number of thread of the compressor, it can't be greater than the number of directory which will be compressed.

`log4jFilePath` specifies the config file path of the compressor loging system

```
#Linux example

dirList=/tmp/test_data1;/tmp/test_data2
outputPath=/tmp
threadNum=2
log4jFilePath=/tmp/Log4J.properties
```

```
#Windows example

#In windows, \ need to be protoected by another \.

dirList=D:\\Multi_Thread_Compressor\\test_data\\data1;D:\\Multi_Thread_Compressor\\test_data\\data2
outputPath=null
threadNum=2
log4jFilePath=D:\\Multi_Thread_Compressor\\Log4J.properties
```

`Log4j.properties` is the config file of the compressor logging system.
If you are not famaliar with log4j framework, Please do not modify this config file

The only line you need to modify after download is `log4j.appender.file.File=`
For example, if you want to put your log in /var/log/codira_data_compression.log (linux) 
or D:\Multi_Thread_Compressor\log\compressor.log.txt (windows) .

You Log4j.properties should look like following example

```
# Root logger option
log4j.rootLogger=DEBUG, stdout, file

# Redirect log messages to console
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.Target=System.out
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n

# Redirect log messages to a log file, support file rolling.
log4j.appender.file=org.apache.log4j.RollingFileAppender
#Linux example
log4j.appender.file.File=/var/log/codira_data_compression.log
#Windows example
log4j.appender.file.File=D:\\Multi_Thread_Compressor\\log\\compressor.log.txt
log4j.appender.file.MaxFileSize=5MB
log4j.appender.file.MaxBackupIndex=10
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n
```

### Running the tool

To run the compressor, you just need to call the MultiThreadCompressor.jar with config.properties as argument


```
# Windows example 
java -jar .\MultiThreadCompressor.jar D:\Multi_Thread_Compressor\config.properties

# Linux example
java -jar MultiThreadCompressor.jar /tmp/config.properties
```

## Versioning

The current stable version is 1.0

## Authors

* **Pengfei Liu** 


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

