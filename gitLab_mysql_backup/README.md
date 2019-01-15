This little program will dump the gitlab mysql db and copy it in a backup floder
which named by the date of the creation.

It will keep last 7 day backup, for the older backup, it only keeps the friday backup for whole week as longterm backup. 

logFile will be put under /var/log/mysql_backup/mysql_backup.log.
configfile will be put under /etc/mysql_backup/MysqlBackup_config.ini .
executable will be put under /usr/local/bin/.

Example of config.ini

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Database]
dbUserName=toto
dbPwd=changeMe
dbName=gitlabhq_production

[BackUp]
backupFolderPath=/mysql_backups/
longTermBackupFolderPath=/mysql_backups/longterm/

[Log]
logFilePath=/var/log/mysql_backup/mysql_backup.log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
