#!/bin/bash
#***********************************************************************
#* FILENAME :        update.sh          DESIGN REF: NON-COMMERCIAL - BETA/MVP
#*
#* DESCRIPTION :  Process to begin update for attention repo, source and db (sync_manager.py)
#*     
#* PUBLIC FUNCTIONS :
#*      
#*
#* NOTES :  	    Writing out p2additional git pull to cloudsync.log
#*                  added in a prune for ref head errors on git that crop up from time to time
#*                  Commented out, but the beginning of trapping the actual program name that caused the error.
#*    			    Will begin to add to this to have better error trapping. 
#*April 17, 2019	Added in name to identify prog name running, lock to prevent concurrent runs, and email to send log file - will ultimately be sent to the cloud with same dashboard as reporting
#*					This file will only email if there is something that went wrong.
#*                  ***NEED TO ADD IN INTEGRITY CHECKS FOR DB
#*
#* CHANGES :  
#*         Added in crontab to update 
#*		   adding in cp of sqlite3 db for backup,, including siam db
#* REF NO  VERSION DATE    WHO     DETAIL
#* 
#*
#**/


NAME="$(basename $0)"       # program name, can be alphanumeric string
LOCKFILE="/tmp/$NAME.lock"  # lock file to prevent concurrent runs
EMAIL="admin@myvanrobot.com"  # email to send fail log
VRFILE="/home/pi/abii_development/hulk/LessonController/lesson_provider/db.sqlite3"
SIAMFILE="/home/pi/cloud_sync_siam/abiicloudengine/abiicloudenginedb.sqlite3"
TUPLEFILE="/home/pi/abii_development/hulk/tuple.sqlite3"


tmpdir="$(mktemp -d /tmp/$NAME-XXXXXX)"

log="$tmpdir/log"

fifo="$tmpdir/fifo"

# log file
log="$(mktemp /tmp/$NAME.log.XXXXXX)"

error='' # error flag for functions below

# runs at exit, sends email if needed
exitHandler() {
	if [ "$error" ]; then
		mv $log $log.txt && log=$log.txt
		echo "Keeping error log in $log"
		mpack -s 'Error log from $NAME' $log "$EMAIL"
		cd /home/pi
		sudo cat /etc/hostapd/hostapd.conf > hostapd.txt
		mpack -s 'Hostapd' hostapd.txt "$EMAIL"
	else
		rm -r $tmpdir
	fi
}

# runs on error
errorHandler() {
	error=1
	trap '' ERR # only do it once
}

# do the stuff
run() {
	trap errorHandler ERR
	trap exitHandler QUIT EXIT



	echo "Starting $NAME run"

	read -p "name run-press enter"


#**********************************************************************************************************************
# make copy of the db's. Check for existence of /db_backup, if exists, straight copy, if not, mkdir, then copy.
#copy siam db, vr db, and tuple db.

# make copy of the db's. Check for existence of /db_backup, if exists, straight copy, if not, mkdir, then copy.
#copy siam db, vr db, and tuple db.


if [ ! -f "$VRFILE" ]
then echo "Copying vr db"
 cd /home/pi/abii_development/hulk/LessonController/lesson_provider/
echo "Moving to lesson provider"
	cp -v db.sqlite3 /home/pi/db.sqlite3
echo "file copied"
else
	echo "$0: File '${VRFILE}' NOT FOUND."
fi

#*****************************************************************************************************************
#copy the siam db - put in validation for file exists and positive copy

echo "Copying abiicloudengine.sqlite3"
	cd /home/pi/cloud_sync_siam/abiicloudengine/
echo "Switching to abiicloudengine"
	cp -v abiicloudenginedb.sqlite3 /home/pi/abiicloudenginedb.sqlite3
echo "file copied"
#**********************************************************************************************************************
#copy the tuple db - put in validation for file exists
echo "Copying tuple.sqlite3"
	cd /home/pi/abii_development/hulk/
echo "Switching to hulk"
	cp -v tuple.sqlite3 /home/pi/tuple.sqlite3
echo "File copied"
pwd

#**********************************************************************************************************************

#if no /dbackup exist, create it, then copy.
#else
#	echo "Creating Directory"
#
#	read -p "creating directory"
#
#	cd /home/pi
#pwd
#read -p "making folder for backup"
#	mkdir dbackup
#
#read -p "folder created"	
#read -p "Creating backup"
#
#	read -p "creating dbackup"
#
#read -p "Press [Enter] key to continue..."
#	
#
#	cd /home/pi/abii_development/hulk/LessonController/lesson_provider/
#	cp -v db.sqlite3 /home/pi/dbackup/db.sqlite3
#read -p "copied vr db"	
#	cd /home/pi/cloud_sync_siam/abiicloudengine/
#	cp -v abiicloudenginedb.sqlite3 /home/pi/dbackup/abiicloudenginedb.sqlite3
#read -p "copied siam db"
#	cd /home/pi/abii_development/
#	cp -v tuple.sqlite3 /home/pi/dbackup/tuple.sqlite3
#read -p "copied tuple db"
#fi

#**********************************************************************************************************************


# update attention repo

	cd /home/pi/attention
	sudo git pull


read -p "Pulling from attention repo-press enter"

# update cloud_sync_siam repo
	cd /home/pi/cloud_sync_siam
	
	sudo git remote set-url origin https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/cloud_sync_siam.git

read -p "checking out p2addtional-press enter"

	sudo git checkout phase2additional
	sudo git gc --prune=now
	sudo git pull

read -p "pulling and pruning-press enter"

	echo "pull and pruned phase2dditional"

read -p "changing folder to abiicloudengine-press enter"

	cd /home/pi/cloud_sync_siam/abiicloudengine

read -p "making migrations"
	sudo python3 manage.py makemigrations

read -p "migrating-press enter"

	sudo python3 manage.py migrate


# abii_development updates
	cd /home/pi/abii_development
read -p "Press [Enter] key to continue..."
	sudo git checkout /home/pi/abii_development/hulk/tuple.sqlite3
	
read -p "Running sync manager-press enter"
# source env/bin/activate
	sudo python3 /home/pi/abii_development/hulk/Syncer/sync_manager.py

read -p "Running crotab-press enter"

	crontab - < /home/pi/abii_development/hulk/Syncer/cron.txt


	echo "Finished $NAME run"
}


# set exit and error traps
trap exitHandler QUIT EXIT
trap errorHandler ERR

# lock to prevent concurrent execution
exec 9>>"$LOCKFILE"
flock --nonblock 9 #lock
if [ $? != 0 ]; then
	logmsg "Already running, lockfile $LOCKFILE"
	exit 1
fi
# run trap on error
set -e 

# write from fifo to syslog
mkfifo $fifo
(logger -t "$NAME" -f $fifo &)

# run and save output in log file and fifo
run 2>&1 |tee $log $fifo
# save exit code
ret=${PIPESTATUS[0]} 
# relinquish lock
exec 9>&- 

exit $ret
