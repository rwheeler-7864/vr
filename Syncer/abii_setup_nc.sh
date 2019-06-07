#!/bin/bash

# '''''
# ***********************************************************************
# * FILENAME :        abii_setup_nc.py            DESIGN REF: NON-COMMERCIAL - BETA/MVP
# *
# * DESCRIPTION :
# *       NON-COMMERCIAL DISTRIBUTION ROUTINE FOR REMOTE ABII SETUP - ABii from
# *       SD card is already setup with repos.  For this version, we only need
# *       to check for dependencies and setup cron job.	   
# *
# * PUBLIC FUNCTIONS :
# *      
# *
# * NOTES : 3.21.2019 - need to switch path back to /home/pi/abii_development
# * The earlier code below was appending whatever we had in the `.txt` to crontab, but it only works if crontab already exists. 
# * The new one just creates the crontab file using whatever is in the `.txt`.
# * REPLACED THIS LINE - crontab -l -u pi | cat - /home/pi/abii_development/hulk/Syncer/cron.txt | crontab -u pi -
# * 
# * AUTHOR :           START DATE :    10 Feb 2019
# *
# * CHANGES : see notes 
# *
# * REF NO  VERSION DATE    WHO     DETAIL
# * 
# *
# **/
# '''''


# # start - for commercial version - commented out due to no need for this automatic setup with non commercial beta
# '''''
cd /home/pi
sudo chown -R pi:pi .
sudo chmod -R u+w /home/pi/
sudo chmod -R o-rwx /home/pi/
#git clone https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/abii_development.git
# cd abii_development

# virtualenv -p python3 env
# source env/bin/activate
# '''''

# configure git in attention repo for easier pulls


cd /home/pi/attention
sudo git remote set-url origin https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/attention.git

# get latest codes into abii_development
# (since we are doing pip3 install -r requirements.txt later)
cd /home/pi/abii_development
sudo git remote set-url origin https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/abii_development.git
sudo git pull

cd /home/van_settings
cp -v van_settings.py /home/pi/abii_development/hulk/SocialBehaviorController/van_settings.py

cd /home/pi/abii_development 

# install dependencies if not already there
# if there, will display something like
# 0 upgraded, 0 newly installed, 0 to remove and 52 not upgraded
sudo apt-get -y update
sudo apt-get -y install libpq-dev python3-dev libffi-dev
sudo apt-get -y dist-upgrade

sudo pip3 install -r requirements.txt
sudo pip2 install websocket_client

# remove database that might be there
# historical git & gitignore legacy
sudo rm /home/pi/abii_development/hulk/LessonController/lesson_provider/db.sqlite3

# initialize sqlite;
sudo python3 hulk/LessonController/lesson_provider/manage.py migrate

# now we have an empty db with tables
# and we populate with a dump from Azure
sudo python3 hulk/Syncer/initial_sync.py

# add cron job
#The earlier code below was appending whatever we had in the `.txt` to crontab, but it only works if crontab already exists. 
#The new one just creates the crontab file using whatever is in the `.txt`.
#crontab -l -u pi | cat - /home/pi/abii_development/hulk/Syncer/cron.txt | crontab -u pi -
echo "$(cat /home/pi/abii_development/hulk/Syncer/cron.txt)" | crontab -
