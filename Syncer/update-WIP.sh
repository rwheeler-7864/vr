#!/bin/bash
#***********************************************************************
#* FILENAME :        update_new_test.sh          DESIGN REF: NON-COMMERCIAL - BETA/MVP
#*
#* DESCRIPTION :  A more sophisticated script Process to begin update for attention repo, source and db (sync_manager.py)
#*     
#* PUBLIC FUNCTIONS :
#*      
#*
#* NOTES :  
#*
#* AUTHOR :           START DATE :    10 Feb 2019
#*
#* CHANGES :  
#*         Added in crontab to update 
#*
#* REF NO  VERSION DATE    WHO     DETAIL
#* 
#*
#**/
#
#!/bin/bash
# Usage:
#   ./update_git_repos.sh [parent_directory] 
#   example usage:
#       ./update_git_repos.sh C:/GitProjects/ [MAKE SURE YOU USE / SLASHES]

# DO NOT RUN THIS...IT'S IN PROGRESS

#!/bin/bash

repos=( 
  "/home/pi/abii_development"
  "/home/i/cloud_sync_siam"
  "/home/pi/attention"
  "/home/pi/cloud_sync_siam/abiicloudengine"
)

echo ""
echo "Getting latest for" ${#repos[@]} "repositories using pull --rebase"

for repo in "${repos[@]}"
do
  echo ""
  echo "****** Getting latest for" ${repo} "******"
  cd "${repo}"
  git pull --rebase
  echo "******************************************"
done