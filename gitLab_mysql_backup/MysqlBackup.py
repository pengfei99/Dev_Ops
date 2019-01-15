#!/usr/bin/python

'''
Created on Nov 18, 2015

@author: pliu
'''
import datetime
from subprocess import Popen,PIPE
import logging,logging.handlers
from os import walk
import smtplib
from email.mime.text import MIMEText
import sys
from ConfigParser import SafeConfigParser

def CreateDailyBackup(backupFolderPath,dbUserName,dbPwd,dbName):
    hasError=False
    #currentDate will be the name of the fold which contains the DB dump and website content
    currentDate=datetime.datetime.now().strftime("%Y-%m-%d")
    #create backup file folder
    folderName=backupFolderPath+currentDate
    mkdirCommand="mkdir -p "+folderName
    mkdirSuccess= run(mkdirCommand)
    if mkdirSuccess==False:
        logging.error('mkdir failed')
        hasError=True
        #backup Failed, notify admin
    
    #if the backup folder is created, Dump the database in the folder
    dumpFileName=folderName+"/gitlab_mysql.sql"
    dumpCommand="mysqldump --user="+dbUserName+" --password="+dbPwd+" --databases "+dbName+" > "+dumpFileName
    dumpSuccess=run(dumpCommand)
    if dumpSuccess==False:
        logging.error('dump failed')
        hasError=True 
        #dump DB failed, notify amdin
 
    
    #zip the folder after copy the DB dump and website content
    zipName=backupFolderPath+currentDate+".tar.gz"
    zipCommand="tar -zcvf "+zipName+" -C / "+folderName[1:]
    zipSuccess=run(zipCommand)
    #print zipCommand
    if zipSuccess==False:
        logging.error('zip backup failed')
        hasError=True 
    
    #clean junk file
    cleanCommand="rm -rf "+folderName
    cleanSuccess=run(cleanCommand)
    if cleanSuccess==False:
        logging.error('clean failed')
        hasError=True
    
    if hasError==True:
        sendAlert() 


def run(cmd):
    logging.info('running:'+cmd)
    p = Popen(cmd, stderr=PIPE, stdout=PIPE, shell=True)
    output, errors = p.communicate()
#    print [p.returncode, errors, output]
    if p.returncode or errors:
#        print 'command',cmd,"exit with errors!!! output: ",errors
        logging.error('command '+cmd+" exit with errors!!! output: "+errors)
        return False
    else:
        logging.info('command '+cmd+" exit with success!!!"+output) 
        return True

def BackUpRotate(backupFolderPath,longTermBackupFolderPath):
    
    today=datetime.datetime.today()
    weekd=today.weekday()
    allBackups = []
    #if today is sunday, start the backup rotate process
    if weekd==6:      
        for (dirpath, dirnames, filenames) in walk(backupFolderPath):
            allBackups.extend(filenames)
            break        
    #print allBackups
    if len(allBackups)>7:
        for backup in allBackups:
            try:
                backupdate=datetime.datetime.strptime(backup[0:10],"%Y-%m-%d")
            except:
                logging.error("Backup folder is corruped with unknow files")
                sendAlert()
                sys.exit(1)
            #If the backup is 7 days old or plus
            if (today-backupdate)>datetime.timedelta(days=7):
                #if the backup is a long term backup, we put it in the long term backup folder, if not delete it
                if backupdate.weekday()==4:
                    moveBackupCommand="mv "+ backupFolderPath+backup+" "+longTermBackupFolderPath
                    logging.info("move long term backup"+backup+"to the long term backup folder"+longTermBackupFolderPath)
                    run(moveBackupCommand)
                else :
                    removeBackupCommand="rm "+backupFolderPath+backup
                    logging.info("delete useless backup "+backup)
                    run(removeBackupCommand)
            
def sendAlert():
    source="admin@etriks.org"
    dest=["pliu@cc.in2p3.fr","benjamin.guillon@cc.in2p3.fr","gino.marchetti@cc.in2p3.fr"]   
    msg=MIMEText("The word press backup application is broken, please go fix it !!!")
    msg['Subject']="word press backup alert"
    msg['From']=source
    msg['To']=dest
    s=smtplib.SMTP('smtp.in2p3.fr')
    s.sendmail(source, dest, msg.as_string())

def readConfig(ConfigFileName):
    parser=SafeConfigParser()
    parser.read(ConfigFileName)
    return parser

def main():
    #get the configuration from the config.ini file. The default file location is at /etc/wp_backup/config.ini
    configurationFilePath='/etc/mysql_backup/MysqlBackup_config.ini'
    config=readConfig(configurationFilePath)
    dbUserName=config.get('Database','dbUserName')
    dbName=config.get('Database','dbName')
    dbPwd=config.get('Database','dbPwd')
    logFilePath=config.get('Log','logFilePath')
    backupFolderPath=config.get('BackUp','backupFolderPath')
    longTermBackupFolderPath=config.get('BackUp','longTermBackupFolderPath')

    #configuration of logger
    FORMAT="%(asctime)-15s %(message)s"
    logging.basicConfig(format=FORMAT,filename=logFilePath,level=logging.DEBUG,datefmt='%Y-%m-%d %H:%M:%S')
    CreateDailyBackup(backupFolderPath,dbUserName,dbPwd,dbName)
    BackUpRotate(backupFolderPath,longTermBackupFolderPath)
    
main()