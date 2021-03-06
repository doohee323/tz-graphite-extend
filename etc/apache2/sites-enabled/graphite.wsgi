import os, sys
sys.path.append('/opt/graphite/webapp')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'graphite.settings')

import django

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()

# READ THIS
# Initializing the search index can be very expensive, please include
# the WSGIImportScript directive pointing to this script in your vhost
# config to ensure the index is preloaded before any requests are handed
# to the process.
#from graphite.logger import log
#log.info("graphite.wsgi - pid %d - reloading search index" % os.getpid())
#import graphite.metrics.search
