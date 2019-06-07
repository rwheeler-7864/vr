#!/bin/bash
#***********************************************************************
#* FILENAME :        simple_log_rotate.sh           DESIGN REF: NON-COMMERCIAL - BETA/MVP
#*
#* DESCRIPTION :  Rotate log files every 1 month, on the 15th of each month. 
#*     
#* PUBLIC FUNCTIONS :
#*      
#*
#* NOTES :
#*       
#* 
#* AUTHOR :           START DATE :    10 Feb 2019
#*
#* CHANGES :  
#*             
#*
#* REF NO  VERSION DATE    WHO     DETAIL
#* 
#*
#**/

echo "rotating log files"

# make copy of main file
sudo cp -v /home/pi/abii_development/cron.log /home/pi/abii_development/cron_history.log
# empty main file
sudo bash -c '> /home/pi/abii_development/cron.log'