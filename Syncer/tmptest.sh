if [ -d /home/pi/dbackup ]
then
    echo "Directory exists"
    cd /home/pi/abii_development/hulk/LessonController/lesson_provider/
	cp -v db.sqlite3 /home/pi/dbackup/db.sqlite3
	cd /home/pi/cloud_sync_siam/abiicloudengine/
	cp -v abiicloudenginedb.sqlite3 /home/pi/dbackup/abiicloudenginedb.sqlite3

else
	cd/home/pi
	mkdir dbackup
	cd /home/pi/abii_development/hulk/LessonController/lesson_provider/
	cp -v db.sqlite3 /home/pi/dbackup/db.sqlite3
	cd /home/pi/cloud_sync_siam/abiicloudengine/
	cp -v abiicloudenginedb.sqlite3 /home/pi/dbackup/abiicloudenginedb.sqlite3
fi