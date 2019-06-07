import os
import sys
import django

dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(os.path.join(os.path.dirname(dir_path), 'LessonController'), 'lesson_provider'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lesson_provider.settings')
django.setup()

import logging
# Get an instance of a logger
logger = logging.getLogger(__name__)

from templates.models import Beta
from django.contrib.contenttypes.models import ContentType
from django.core import management


def initial_sync():
    logger.info('Making .json copy of Azure data.')
    management.call_command(
        'dumpdata',
        '--database=azure_db', # additional connection specified in settings.py
        output=os.path.join(dir_path, 'initial_dump.json'),
        verbosity=1,
    )

    logger.info('Clear up contenttypes table')
    ContentType.objects.all().delete()

    logger.info('Loading local data.')
    management.call_command(
        'loaddata', os.path.join(dir_path, 'initial_dump.json')
    )

    # remove initial dump
    os.remove(os.path.join(dir_path, 'initial_dump.json'))

    logger.info('Initial Database Construction Success.')


####################################################
# define main
if __name__ == '__main__':
    initial_sync()