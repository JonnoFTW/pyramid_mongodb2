from datetime import datetime
from pymongo.cursor import Cursor

from pyramid_debugtoolbar.panels import DebugPanel


class DebugMongo:
    """
    A simple wrapper for a mongodb database. Logs all calls made
    """

    def __init__(self, conn, request):
        self.conn = conn
        self.request = request

    def _get_conn(self, item):
        coll = self.conn[item]

        def coll_attr(attr):
            target_attr = getattr(coll, attr)
            if hasattr(target_attr, '__call__'):
                # we need to wrap this callable
                def wrapper(*args, **kwargs):
                    start = datetime.now()
                    response = target_attr(*args, **kwargs)
                    duration = datetime.now() - start
                    doc = {
                        'duration': duration,
                        'db': coll.database,
                        'collection': coll,
                        'op': target_attr.__name__,
                        'args': args,
                        'kwargs': kwargs
                    }
                    if isinstance(response, Cursor):
                        doc['cursor'] = response
                    self.request.query_log.append(doc)
                    return response

                return wrapper
            else:
                return target_attr

        class DebugCollection:
            def __init__(self, coll):
                self.coll = coll

            def __getattr__(self, item):
                return coll_attr(item)

        return DebugCollection(coll)

    def __getattr__(self, item):
        return self._get_conn(item)

    def __getitem__(self, item):
        return self._get_conn(item)


class MongoToolbar(DebugPanel):
    """
    MongoDB Debugtoolbar Panel
    """
    name = 'mongodb_panel'
    is_active = True
    has_content = True
    title = 'MongoDB'
    nav_title = 'MongoDB'
    template = 'pyramid_mongodb2:templates/mongo.mako'

    def __init__(self, request):
        super().__init__(request)
        self.data = {'request_path': request}
        self.request = request

    def process_response(self, response):
        self.data['request'] = self.request
