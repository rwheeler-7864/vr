#!/bin/bash
#!/bin/bash
#***********************************************************************
#* FILENAME :        update.sh          DESIGN REF: NON-COMMERCIAL - BETA/MVP
#*
#* DESCRIPTION :  Process to begin update for attention repo, source and db (sync_manager.py)
#*     
#* PUBLIC FUNCTIONS :
#*      
#*
#* NOTES :  writing out p2additional git pull to cloudsync.log
#*          added in a prune for ref head errors on git that crop up from time to time
#*          Commented out, but the beginning of trapping the actual program name that caused the error.
#*          Will begin to add to this to have better error trapping. 
#*			Added in 
#* AUTHOR :           START DATE :    10 Feb 2019
#*
#* CHANGES :  
#*         Added in crontab to update 
#*		   adding in cp of sqlite3 db for backup,, including siam db
#* REF NO  VERSION DATE    WHO     DETAIL
#* 
#*
#**/


#need to add this after mvp, for better error trapping and loggin
#PROGNAME=$(basename $0)
#error_exit()
#echo "${PROGRNAME}: ${1:-"Unknown Error"}" 1>&2

echo "ABii update process called"

# make copy of the db. Check for existence of /db_backup, if exists, straight copy, if not, mkdir, then copy.


cd /home/pi/abii_development/hulk/LessonController/lesson_provider/
cp -v db.sqlite3 /home/pi/db.sqlite3

#create backup copies of the db's
cd /home/pi/cloud_sync_siam/abiicloudengine/
cp -v abiicloudenginedb.sqlite3 /home/pi/abiicloudenginedb.sqlite3

cd /home/pi/abii_development/hulk/LessonController/lesson_provider
cp -v db.sqlite3 /home/pi/db.sqlite3

cd /home/pi/abii_development/hulk/
cp -v tuple.sqlite3 /home/pi/tuple.sqlite3


# update attention repo
cd /home/pi/attention
sudo git pull

# update cloud_sync_siam repo
cd /home/pi/cloud_sync_siam
sudo git remote set-url origin https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/cloud_sync_siam.git
sudo git checkout phase2additional
#eventually write out this log file to /logs folder for all sync activities.
sudo git gc --prune=now
sudo git pull > cloudsync.log  

echo "pull and pruned phase2dditional"


cd /home/pi/cloud_sync_siam/abiicloudengine
sudo python3 manage.py makemigrations
sudo python3 manage.py migrate

# abii_development updates
cd /home/pi/abii_development
sudo git checkout /home/pi/abii_development/hulk/tuple.sqlite3
# source env/bin/activate
sudo python3 /home/pi/abii_development/hulk/Syncer/sync_manager.py
echo "$(cat /home/pi/abii_development/hulk/Syncer/cron.txt)" | crontab -
