'''''
**********************************************************************
* FILENAME :        sync_manmager.py            DESIGN REF: NON-COMMERCIAL - BETA/MVP
*
* DESCRIPTION :
*       Manages the sync process 
*
* PUBLIC FUNCTIONS :
*      
*
* NOTES :
*       
* 
* AUTHOR :              START DATE :    10 Feb 2019
*
* CHANGES :
*
* REF NO  VERSION DATE    WHO     DETAIL
* 
*
**/

'''


import os
import sys
import django
import requests
import json
import time
from django.urls import reverse

dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(os.path.join(os.path.dirname(dir_path), 'LessonController'), 'lesson_provider'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lesson_provider.settings')
django.setup()

import logging
# Get an instance of a logger
logger = logging.getLogger(__name__)


from default.versions import (
    SOURCE_CODE_VERSION, LESSON_CONTENT_VERSION
)
from db_sync_json import sync_tables
from code_file_sync import sync_source_code


azure_app_base_url = 'https://vanroboticsapp.azurewebsites.net'



def start_sync(retry_n=10, retry_interval=10):
    """
    This funtion serves as an entry point to the whole syncing process
    within Python.
    scheduled cron job should call this function, and let things start from here.

    if seemingly update is not success, we retry after retry_interval secs
    and we retry for a maximum of retry_n times
    if still no luck, we abort anyway, and hope the next scheduled update works


    Two potential types: SOURCE_CODE, and LESSON_CONTENT.
    If only source code:
        Only need to do source code update (and associated operations)
    If Lesson content updated:
        Need to update both Database and Source Code
        (since lesson content involves static files)

    """

    # status file
    file_name_raw = 'update_status.json'
    file_name = os.path.join(dir_path, file_name_raw)

    ####################################################
    # Step 1
    # check for what update is needed.
    i = 0
    while i < retry_n:
        try:
            to_update = check_update()
            i = retry_n
        except Exception as e:
            logger.error(e)
            # if not == [], we got to try again
            i += 1
            logger.info('Cannot connect to remote server. Will retry in {} seconds. \
                This will be the {} attempt.'.format(str(retry_interval), str(i+1)))
            time.sleep(retry_interval)
            if i == retry_n:
                logger.info('Cannot connect to remote server. Exhausted retry attempts. Aborting update.')
                return

    # also check status file (may have leftover to-dos from last time)
    to_update_2 = check_status_file(file_name)

    # combine the two
    to_update = list(set(to_update + to_update_2))

    # set a retry limit
    i = 0
    while i < retry_n:

        try:

            if to_update == []:
                to_update = ['Nothing to update.']
                logger.info('Updates to perform: {}'.format(' '.join(to_update)))
                return

            logger.info('Updates to perform: {}'.format(' '.join(to_update)))

            ####################################################
            # write to_update into a log file
            # so we know if a process fails half-way
            # and can retry it
            update_status = {}
            for item in to_update:
                # 0 for not updated yet
                update_status[item] = 0

            with open(file_name, 'r+') as monitor_file:
                monitor_file.seek(0)  # rewind
                json.dump(update_status, monitor_file)
                monitor_file.truncate()

            ####################################################
            # 'LESSON_CONTENT' update: whole thing
            if 'LESSON_CONTENT' in to_update:
                # first do source code update
                do_sync_source_code(file_name)
                # now do DB update
                do_sync_table(file_name)

            # if we get here, means no LESSON_CONTENT update
            elif 'SOURCE_CODE' in to_update:
                # source code only
                do_sync_source_code(file_name)

        except Exception as e:
            logger.error(e)

        ####################################################
        # got here: no updates to do, or required updates are (supposedly) done
        # let's double check (in fact, let's check and retry multiple times
        # before we give up)
        to_update = check_status_file(file_name)
        if to_update == []:
            logger.info('Updates are performed successfully')
            return
        # if not == [], we got to try again
        i += 1
        logger.info('Some updates failed. Will retry in {} seconds. \
            This will be the {} attempt.'.format(str(retry_interval), str(i+1)))
        time.sleep(retry_interval)

    # if we get here, it means all attempts have failed
    logger.info('Some updates failed after specified retries. Aborting.')



####################################################
# helpers
def do_sync_table(file_name):
    sync_tables()
    # mark success (may want more refined monitoring)
    with open(file_name, 'r+') as monitor_file:
        try:
            status = json.load(monitor_file)
        except json.JSONDecodeError:
            status = {}
        status['LESSON_CONTENT'] = 1
        monitor_file.seek(0)  # rewind
        json.dump(status, monitor_file)
        monitor_file.truncate()


def do_sync_source_code(file_name):
    res = sync_source_code()
    # mark success (may want more refined monitoring)
    with open(file_name, 'r+') as monitor_file:
        try:
            status = json.load(monitor_file)
        except json.JSONDecodeError:
            status = {}
        status['SOURCE_CODE'] = 1 if res else 0
        monitor_file.seek(0)  # rewind
        json.dump(status, monitor_file)
        monitor_file.truncate()


def check_status_file(file_name):
    try:
        to_update = []
        with open(file_name, 'r+') as monitor_file:
            try:
                status = json.load(monitor_file)
            # empty file
            except json.JSONDecodeError:
                return []

        # append all that are not 1
        for key in status:
            if status[key] != 1:
                to_update.append(key)
        return to_update

    except FileNotFoundError:
        with open(file_name, 'w+') as f:
            pass
        return []


def check_update():
    """
    fetches latest version from Azure web app API;
    compares with own version
    returns necessary updates:
    Update types:
        1. Source Code;
        2. Lesson Content
    """

    to_update = []

    check_url = azure_app_base_url + reverse('latest_version')
    # make GET request to the version endpoint
    res = requests.get(check_url)
    # parse to json
    master_versions = json.loads(res.content)

    # compare with local version
    if parse_version(SOURCE_CODE_VERSION) \
            < parse_version(master_versions['SOURCE_CODE_VERSION']):
        to_update.append('SOURCE_CODE')

    if parse_version(LESSON_CONTENT_VERSION) \
            < parse_version(master_versions['LESSON_CONTENT_VERSION']):
        to_update.append('LESSON_CONTENT')

    return to_update


def parse_version(version_str):
    """
    reads in 'x.x.x',
    returns int: xxx
    """
    return int(version_str.replace('.', ''))


####################################################
# define main
if __name__ == '__main__':
    start_sync()