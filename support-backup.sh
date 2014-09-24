#!/bin/bash
#
#Karl G Chavarria
#02-08-2011
#
#Earlier (and obsolete) per-app backup script written before I made the universal web app backup script
#
BACKUP_RETENTION=5 #days
DATE=`date '+%m-%d-%Y'`
BACKUP_DIR=/some_backup_dir/backup/
################################################################################################################################################################
usage()
{ #Echoes a usage statement and exits script.
echo "\n\nUsage Statement, conf info\n\n";
#exit;
}
################################################################################################################################################################
check()
{ #Ensures conf file is present and then calls sanitycheck
Look for conf file
if [no conf file]; then
	usage;
else
	sanitycheck;
fi
}
################################################################################################################################################################
sanitycheck()
{ #Ensures conf file is in the correct format
Check format of conf file
if [!good]; then
	usage;
else
	HOSTLIST=`grep "HOSTNAME:" backup.conf|cut -f2 -d:|sed -e 's/ //g' -e 's/$/ and /g'|tr -d \\\n| sed 's/ and $//g'`
	echo -e "\n\nHosts: $HOSTLIST will be backed up.\n\n"
	read;
fi
}
################################################################################################################################################################
read()
{ #Parse through conf file,read variables and initialize backup

for((i=0; i < `grep HOSTNAME backup.conf | wc -l`; i++)); do
        lower=$((5*$i+1))
        higher=$((5*$i+5))

        array1=( `egrep -v \('^$'\|'^#$'\) backup.conf | tr -d ' ' | awk 'NR=='$lower',NR=='$higher''`)

        #Variables defined:
        ALL=${array1[@]}
        HOST_NAME=${array1[0]}
        DIR=${array1[1]}
        DB=${array1[2]}
        DB_USER=${array1[3]}
        DB_PASS=${array1[4]}

#       echo -e "$HOST_NAME\n$DIR\n$DB\n$DB_USER\n$DB_PASS\n"          #for debug
#       echo -e "\nLoop $i\n"                                          #for debug
        backup;

done
}
################################################################################################################################################################
backup()
{
################################################################################
check_variables()
{ #Checks the variables for any hash symbols (ignore flags)

VAR_LIST=`echo -e "$HOST_NAME\n$DIR\n$DB\n$DB_USER\n$DB_PASS\n"`
VLIST_DB=`echo -e "$VAR_LIST" | grep  -c '^#DB'`
VLIST_DIR=` echo -e "$VAR_LIST"  | grep -c '^#DIR'`
VLIST_HASH=` echo -e "$VAR_LIST" | grep -c "#"`
echo -e "\n\nVAR_LIST=\n$VAR_LIST\n"
#echo -e "\n\nVLIST_DB=\n$VLIST_DB\n\n"				       #for debug
#echo -e "\n\nVLIST_DIR=\n$VLIST_DIR\n\n"			       #for debug
#echo -e "\n\nVLIST_HASH=\n$VLIST_HASH\n\n"			       #for debug

if [ $VLIST_HASH != 0 ]; then                                          #if there are any hashes at all in the variables
echo -e "\nhashes found!\n"
        if [[ "$VLIST_DB" != 0 && "$VLIST_DIR" != 0 ]]; then           #if there are hashes in all the variables, back up nothing
                echo -e "\nBacking up nothing!\n"
        else
                if [ $VLIST_DB != 0 ]; then                            #if there are hashes in DB variables only, only do file backup
                        file_backup;
                else
                        db_backup;                                     #if there are hashes in the file variables only, do DB backup.
                fi
        fi
else
echo -e "\nNo hashes found, do full backup\n\n"
        db_backup;
        file_backup;
fi
}
################################################################################
db_backup()
{ #Does mysql database backup
DB=`echo $DB | cut -f2 -d:`					       #remove $DB: prefix from $DB variables
DB_USER=`echo $DB_USER | cut -f2 -d:`
DB_PASS=`echo $DB_PASS | cut -f2 -d:`

echo -e "Backing up $DB database to /tmp/database_$DB"_"$DATE.sql.gz\n"

#/usr/bin/mysqldump -u $DB_USER -p$DB_PASS --databases $DB | gzip --rsyncable > /tmp/database_$DB'_'$DATE.sql.gz

transfer_files;
}
################################################################################
file_backup()
{ #Backs up defined directories
DIR=`echo $DIR | cut -f2 -d:`					       #remove #DIR: prefix from $DIR variable

echo -e "Do file backup via ssh\n"

for x in $(echo $DIR | tr , ' ')
do
	FILEMIDNAME=`echo $x | tr / _`
	FILENAME=`echo "dir\$FILEMIDNAME\$DATE.gz"`
	echo -e "Backing up $x to /tmp/$FILENAME\n" 

#       tar -cp $x | gzip --rsyncable > /tmp/dir_$x'_'$DATE.gz
done

transfer_files;
}
################################################################################
transfer_files()
{ #Rsyncs the backed up files to my machine
echo -e "Do filetransfer via rsync\n"

#rsync $? to  $BACKUP_DIR$HOSTNAME
}
################################################################################

check_variables;
}
######################### Main Function Start ##################################################################################################################
main()
{ #main function
read;
}
main;







