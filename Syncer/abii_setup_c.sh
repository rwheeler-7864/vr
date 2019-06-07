# DO NOT RUN THIS SCRIPT
#!/bin/bash

# """"""***********************************************************************
# * FILENAME :        abii_setup_c.py            DESIGN REF: COMMERCIAL
# *
# * DESCRIPTION :
# *       COMMERCIAL DISTRIBUTION ROUTINE FOR REMOTE ABII SETUP AUTOMATED
# *
# * PUBLIC FUNCTIONS :
# *       int     FM_CompressFile( FileHandle )
# *       int     FM_DecompressFile( FileHandle )
# *
# * NOTES :
# *       These functions are a part of the FM suite;
# *       See IMS FM0121 for detailed description.
# * 
# * AUTHOR :           START DATE :    10 FEB  2019
# *
# * CHANGES :
# *
# * REF NO  VERSION DATE    WHO     DETAIL
# *      
# *
# **

# """"""


# # start - for commercial version - commented out due to no need for this automatic setup with non commercial beta

# cd /home/pi
# sudo chown -R pi:pi .
# sudo chmod -R u+w /home/pi/
# sudo chmod -R o-rwx /home/pi/
# git clone https://rwheeler-7864:195ede36ce2278ea1f2240e6257ad8101b76f7c9@github.com/van-robotics/abii_development.git
# cd abii_development

# virtualenv -p python3 env
# source env/bin/activate

# # install dependencies if not already there
# # if there, will display something like
# # 0 upgraded, 0 newly installed, 0 to remove and 52 not upgraded
# sudo apt-get update
# sudo apt-get install libpq-dev python3-dev libffi-dev
# sudo apt-get dist-upgrade

# #pip3 install -r requirements.txt

# # initialize sqlite;
# python3 hulk/LessonController/lesson_provider/manage.py migrate


# # now we have an empty db with tables
# # and we populate with a dump from Azure
# python3 hulk/Syncer/initial_sync.py

# # add cron job
# # this appends whatever is in cron.txt into the crontab
# # NOTE: cron.txt must has an empty line at the end
# # because crontab requires that
# crontab -l -u pi | cat - /home/pi/abii_development/hulk/Syncer/cron.txt | crontab -u pi -
