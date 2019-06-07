'''''***********************************************************************
* FILENAME :        code_file_sync.py            DESIGN REF: NON-COMMERCIAL - BETA/MVP
*
* DESCRIPTION :
*      Sync file to manage the git pull process for updating code base from github repo.       
*
* PUBLIC FUNCTIONS :
*      
*
* NOTES :
*       
* 
* AUTHOR :           START DATE :    10 Feb 2019
*
* CHANGES :  Added Source and Target files for van_settings.py copy from archived location.  Each ABii is unique regarding 
*            van_settings, so we keep a copy in /home/van_settings/  so when a pull occurs we can overwrite the incorrect file.
*             
*
* REF NO  VERSION DATE    WHO     DETAIL
* 
*
**/

'''



import subprocess
import os
import sys
import shutil
import django
from django.core import management

dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(os.path.join(os.path.dirname(dir_path), 'LessonController'), 'lesson_provider'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lesson_provider.settings')
django.setup()

import logging
# Get an instance of a logger
logger = logging.getLogger(__name__)

# van settings source file and target file
source = '/home/van_settings/van_settings.py'
target = '/home/pi/abii_development/hulk/SocialBehaviorController/van_settings.py'


def sync_source_code():
    """
    Communicate with Git to update source code and static files (images/audio)
    """
    logger.info('Updating Source Code')
    # git pull, code=0 if no error
    code = subprocess.call(["git", "pull"])
    # deprecated for now, since moving credentials to git url
    # git fetch, not exactly sure why this is needed if pull should already be fetching
    # but getting errors if don't include this, and there are other reports
    # on the net claiming similar issues, so just add it here for robustness
    # code1 = subprocess.call(["git", "fetch"])
    # code = code1 + code2

    # discard changes in this file before checking status to be sure
    subprocess.call(["git", "checkout", "--", target])

    # (although if not success, version would not be updated either)
    res = subprocess.check_output(["git", "status"]).decode('utf-8')
    success = ('is up-to-date with' in res 
               or 'up to date' in res) \
               and code == 0

    # copy original van_settings back into repo to overwrite
    try:
        shutil.copy(source, target)
    except IOError as e:
        logger.error("Unable to copy file. %s" % e)
    except:
        logger.error("Unexpected error:", sys.exc_info())

    # migrate
    logger.info('Migrating...')
    management.call_command('migrate')

    logger.info('Sync Source Code Success')
    return success

