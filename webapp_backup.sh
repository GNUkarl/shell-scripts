#!/bin/bash
#
# Karl Chavarria
# 09-12-2012
# A somewhat universal web app backup script for databases and directories
#
#

WEBAPP='Webapp_Name' # SVN, JIRA, etc.

APP_DIRS='/path/to/dir/1 /path/to/dir/2' # Include the FULL path

DATABASE='db_user:db_pass:db_type:db_name db_user:db_pass:db_type:db_name' #db_type can be postgres or mysql

BACKUP_DIR=/var/backup
DIR_FILENAME=$WEBAPP_DIR_$DATE.tgz
DB_FILENAME=$WEBAPP_DB_$DATE.tgz

########## Webapp Details ##################################################################################
#
#
#
########## Backup Details ##################################################################################

BACKUP_RETENTION=5 #days
DATE=`date +%Y-%m-%d`
DISK_SPACE_LIMIT=2 # Script will quit if there's less than X GB of disk space left on root filesystem

#RSYNC_DIR=user@hostname.domain:/path/to/backups/

########## Config Details ##################################################################################
#
#
#
########## MISC Variables ##################################################################################

UBUNTU_OS=`cat /etc/*release* | grep -ic ubuntu`

############################################################################################################
#
#
#
clean() 
{ # Small function to clean out backup directories before and after script run

rm -rf $BACKUP_DIR/*.sql $BACKUP_DIR/*.tgz $BACKUP_DIR/tmp/
mkdir -p $BACKUP_DIR
mkdir -p $BACKUP_DIR/tmp
mkdir -p $BACKUP_DIR/rsync

echo -e "\n\nCleaning done.\n\n"
}

safetytest()
{ # Safety test to make sure there's enough disk space, etc.

DISK_SPACE=$(df -h| grep "\% \/$"|tr -d ' '|awk 'BEGIN{FS="[G]"} {print $3}')

if [ $(whoami) != "root" ]; then
        echo -e "\n\nMust be root to run this script.\nExiting...\n\n"
        exit
fi

if [ $UBUNTU_OS -gt 1 ]; then

        OUTPUT_LOG=/var/log/syslog
else
        OUTPUT_LOG=/var/log/messages
fi


if [ $( echo "$DISK_SPACE < $DISK_SPACE_LIMIT" | bc) -ne 0 ]; then
        echo "$0 -- $DATE -- There is only $DISK_SPACE GB remaining disk space on $HOSTNAME! Quitting..." >> $OUTPUT_LOG
        exit
fi

if [ $(gzip -h | grep -ic rsyncable) -eq 0 ]; then      # insert code to alias 'gzip' command in case --rsyncable option doesn't exist
        echo -e "\nUsing standard gzip.\n"
else
        alias gzip="gzip --rsyncable"
fi

echo -e "\n\nSafety test done.\n\n"
}

webapp_backup()
{ # Tars up the web app directories

echo -e "\nBacking up $WEBAPP directories...\n"

for x in $APP_DIRS; do
        X_CHILD=`echo $x | sed 's/\/*$//' | awk -F/ '{ print $NF }'`  # variable holds name of last child directory, removes leading parent directories

        echo -e "\nBacking up $x...\n"
        mkdir -p $BACKUP_DIR/tmp/$X_CHILD
        cp -rf $x/* $BACKUP_DIR/tmp/$X_CHILD
        tar -c $BACKUP_DIR/tmp/$X_CHILD | gzip > $BACKUP_DIR/tmp/$X_CHILD.tgz
        rm -rf $BACKUP_DIR/tmp/$X_CHILD/
done

tar -c $BACKUP_DIR/tmp/*.tgz | gzip > $BACKUP_DIR/rsync/$DIR_FILENAME
#rm -rf $BACKUP_DIR/tmp/*

echo -e "\n\nWebapp backup done.\n\n"
}

database_backup()
{ # Dumps the webapp database(s) and tars it/them up

if [ $(echo $DATABASE | grep -c ' ') -eq 0 ]; then    # If only one DB getting backed up, echo first statement; else echo second statement.
        echo -e "\nBacking up $WEBAPP database...\n"
else
        echo -e "\nBacking up $WEBAPP databases...\n"
fi


for x in $(echo $DATABASE); do
        DB_USER=`echo $x | cut -f1 -d:`
        DB_PASS=`echo $x | cut -f2 -d:`
        DB_TYPE=`echo $x | cut -f3 -d: | tr [:upper:] [:lower:]`
        DB_NAME=`echo $x | cut -f4 -d:`

        if [[ ! -z "$DB_USER" ]] && [[ ! -z "$DB_PASS" ]] && [[ ! -z "$DB_TYPE" ]] && [[ ! -z "$DB_NAME" ]]; then

                if [[ $DB_TYPE == "mysql" ]];then
                        mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/tmp/$DB_TYPE_$DB_NAME.sql
                elif [[ $DB_TYPE == "postgres" ]];then
                        pg_dump -U $DB_USER -f $BACKUP_DIR/tmp/$DB_TYPE_$DB_NAME.sql
                else
                        echo -e "\n\nInvalid DB type specified!  Exiting...\n\n"
                        exit
                fi

        fi


# find /var/backup/tmp/ -name "*.sql" -printf "%f\n"
        DB_BACKUP_NAME=$(find $BACKUP_DIR/tmp/ -name "*.sql" -printf "%f\n")

        tar -c $BACKUP_DIR/tmp/$DB_BACKUP_NAME | gzip > $BACKUP_DIR/tmp/$DB_BACKUP_NAME.tgz
        rm -rf $BACKUP_DIR/tmp/$DB_BACKUP_NAME
done

tar -c $BACKUP_DIR/tmp/*sql.tgz | gzip > $BACKUP_DIR/rsync/$DB_FILENAME
#rm -rf $BACKUP_DIR/tmp/*

echo -e "\n\nDatabase backup done.\n\n"
}

rsyncfiles()
{ # Deletes old backups and rsyncs them to my machine

echo -e "\nDeleting backups older than $BACKUP_RETENTION days...\n"

find $BACKUP_DIR/rsync/ -mtime +$BACKUP_RETENTION -type f -exec rm {} \;

echo -e "\nRsyncing backups to targets...\n"
rsync --delete -cav $BACKUP_DIR/rsync/* $RSYNC_DIR

echo -e "\nBackups sent!\n"

echo -e "\n\nRsync done.\n\n"
}

###########################################################################
main()
{ # Main function that ties everything together
clean;
safetytest;
webapp_backup;
database_backup;
rsyncfiles;
clean;

echo -e "$WEBAPP $DIR_FILENAME $DB_FILENAME ::::::  $WEBAPP-DIR-$DATE.tgz"


}
main;

