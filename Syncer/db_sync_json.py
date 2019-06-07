import os
import sys
import re
import django
from django.core import management
from django.utils import timezone
import datetime


dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(os.path.join(os.path.dirname(dir_path), 'LessonController'), 'lesson_provider'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lesson_provider.settings')
django.setup()

from django.contrib.contenttypes.models import ContentType
from templates.models import (
    Lesson, Screen, Course, TutorialScreen,
    ScreenEvent, Choice, Beta
)

import logging
# Get an instance of a logger
logger = logging.getLogger(__name__)


###########################################################
# start sync code
# LessonBranch? Are we still using that?
ALL_MODELS = [
    Lesson, Screen, Course, TutorialScreen,
    ScreenEvent, Choice
]
# just to emphasize the importance of the order
MODELS_order = [
    Course, Lesson, Screen, TutorialScreen,
    ScreenEvent, Choice
]

###########################################################
def sync_tables(MODELS=ALL_MODELS):
    """
    given a list of MODELS, check for updates, and if necessary, 
    sync with remote for the each models within the list,
    """
    logger.info('Updating Local SQLite')
    ###########################################################
    # step 0.1:
    # prepare directory
    # clean up again - in case left over files from last run.
    ###########################################################
    purge_json(dir_path)

    ###########################################################
    # step 0.2:
    # get list of tables that needs updating
    ###########################################################
    update_MODELS = get_available_updates(MODELS)
    # sort it in the order that we need to load them
    update_MODELS = [x for x in MODELS_order if x in update_MODELS]

    ###########################################################
    # step 1: make data dump
    # might be better to move this to be done on cloud server,
    # and have ABii featch the data / files
    ###########################################################
    for MODEL in update_MODELS:
        management.call_command(
            'dumpdata',
            'templates.{}'.format(MODEL.__name__),
            '--database=azure_db', # additional connection specified in settings.py
            '--natural-foreign',
            output=os.path.join(dir_path, 'azure_db_{}.json'.format(MODEL.__name__)),
            verbosity=1,
        )
    logger.info('Step 1 Done.')
    ###########################################################
    # step 2:
    # remove all objects in certain tables from local db
    # !!
    # NOTE: Check for FK references pointing to these MODELS
    # # e.g. Response.choice so all Responses will be lost when
    #        we delete Choice objects
    # We can either 1. sync responses (to cloud?) to save them beforehand, or
    #               2. specify DO_NOTHING for on_delete in models definition
    #                   (which requires extra handling outside of syncing processes)
    ###########################################################
    for MODEL in update_MODELS:
        MODEL.objects.all().delete()
    logger.info('Step 2 Done.')
    ###########################################################
    # step 3:
    # readin all the data from step 1 - need to be in specific order
    # and mark beta table (in local) as synced
    ###########################################################
    for MODEL in update_MODELS:
        management.call_command('loaddata', os.path.join(dir_path, 'azure_db_{}.json'.format(MODEL.__name__)))
        # mark as updated 
        # - might be useful to also update last_updated locally, but not necessary for now
        # since we are comparing with remote
        # if we want to do it, can probably do it in helper "get_available_updates"
        temp = Beta.objects.get(ref_model=ContentType.objects.get_for_model(MODEL))
        temp.last_sync = timezone.now()
        temp.save()
    logger.info('Step 3 Done.')

    # clean up 
    # - remove dump files;
    purge_json(dir_path)

    logger.info('SQLite Update Success.')

    return 'success'


###########################################################
# helpers
###########################################################
def get_available_updates(MODELS):
    """
    given a list of MODELS (=[Lesson, Course, ...])
    compare local last_sync record with remote last_updated timestamp,
    return list of MODELS that needs to be updated
    (within the list of MODELS passed in)
    """
    logger.info('Entering get_available_updates')
    azure_beta = Beta.objects.using('azure_db').all()
    local_beta = Beta.objects.all()
    # compare
    to_update = []
    for MODEL in MODELS:
        last_updated = azure_beta.get(ref_model=ContentType.objects.db_manager('azure_db').get_for_model(MODEL)).last_updated
        last_sync = local_beta.get(ref_model=ContentType.objects.get_for_model(MODEL)).last_sync
        print(MODEL.__name__)
        print(last_updated)
        print(last_sync)
        if last_updated is None:
            continue
        if last_sync is None or last_sync < last_updated:
            to_update.append(MODEL)

    logger.info('Leaving get_available_updates')
    return to_update


def purge_json(dir):
    """
    remove all .json files in the specified directory
    that starts with azure_db - want to keep update_status.json
    """
    for f in os.listdir(dir):
        if re.search('^azure_db.*\.json$', f):
            os.remove(os.path.join(dir, f))