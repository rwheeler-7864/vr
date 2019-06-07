'''''
**********************************************************************
* FILENAME :        lesson_content_bookkeeper.py            DESIGN REF: NON-COMMERCIAL - BETA/MVP
*
* DESCRIPTION :
*       After updating lesson content, 
        run this script (and respond accordingly)
        to update records in:
            1. versions.py
            2. Azure DB beta table last_updated time
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
from django.utils import timezone

dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(os.path.join(os.path.dirname(dir_path), 'LessonController'), 'lesson_provider'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lesson_provider.settings')
django.setup()

import logging
# Get an instance of a logger
logger = logging.getLogger(__name__)

from django.contrib.contenttypes.models import ContentType
from templates.models import (
    Lesson, Screen, Course, TutorialScreen,
    ScreenEvent, Choice, Beta
)

####################################################
# some constants
ALL_MODELS = [
    Course, Lesson, Screen, TutorialScreen,
    ScreenEvent, Choice
]

NO_COURSE = [
    Lesson, Screen, TutorialScreen,
    ScreenEvent, Choice
]

Yes_list = ['Yes', 'yes', 'y', 'Y']
No_list = ['No', 'no', 'n', 'N']
####################################################


####################################################
# python3 hulk/Syncer/lesson_content_bookkeeper.py
####################################################

def bookkeeping():
    """
    asks what to update, and mark last_updated in Azure
    for the selected tables
    """
    print('*******************************')
    print('What tables have been updated?')
    print('For simplicity, just tell us if Course table has been updated.')
    print('\"Yes\" if it has been updated, otherwise \"No\".')

    course_updated = None
    ask = True
    while ask:
        course_updated = input('\"Yes\" or \"No\"?   ')
        if course_updated not in Yes_list \
            and course_updated not in No_list:
            print('Please enter a valid response.')
            print('   ')
        else:
            ask = False

    if course_updated in Yes_list:
        to_update = ALL_MODELS
    elif course_updated in No_list:
        to_update = NO_COURSE

    # now we connect to Azure DB and update beta table
    azure_beta = Beta.objects.using('azure_db').all()
    for MODEL in to_update:
        item = azure_beta.get(ref_model=ContentType.objects.db_manager('azure_db').get_for_model(MODEL))
        item.last_updated = timezone.now()
        item.save()

    print('Azure DB updated successfully.')
    print('Please remember to update versions.py if lesson content is ready for release.')
    print('*******************************')



####################################################
# define main
if __name__ == '__main__':
    bookkeeping()

####################################################
# # if we want to increment versions automatically,
# # might want to modify versions.py into a json file and
# # modify other relevant codes accordingly as well.
# # skipped for now.

# def increment_version():
#     """
#     increase lesson content version by 0.0.1
#     """
#     current_v = default.versions.LESSON_CONTENT_VERSION
#     current_v = int(current_v.replace('.', ''))
#     new_v = str(current_v + 1)
#     # parse back into string
#     if len(new_v) >= 3:
#         new_v = '{}.{}.{}'.format(new_v[:-2], new_v[-2], new_v[-1])
#     elif len(new_v) == 2:
#         new_v = '0.{}.{}'.format(new_v[-2], new_v[-1])
#     else:
#         new_v = '0.0.{}'.format(new_v)
#     default.versions.LESSON_CONTENT_VERSION = new_v
