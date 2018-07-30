from pymongo import MongoClient
import re

from .mongo_toolbar import DebugMongo, MongoToolbar


def includeme(config):
    debug = 'pyramid_mongodb2:MongoToolbar' in config.registry.settings.get('debugtoolbar.includes', '')
    db_url = config.registry.settings.get('mongo_uri')
    if db_url is None:
        raise ValueError("Please set mongo_uri in your configuration")
    mongo_client = MongoClient(db_url,
                               serverSelectionTimeoutMS=10000,
                               connectTimeoutMS=3000,
                               socketTimeoutMS=10000,
                               maxPoolSize=200,
                               maxIdleTimeMs=30000,
                               appname=config.registry.package_name)

    def add_query_log(request):
        return []

    def add_db_conn(request):
        return mongo_client

    def get_database(request, db_name):
        """
        Gets a database from the mongo client
        :param request:
        :param db_name:
        :return:
        """
        if debug:
            return DebugMongo(request.db[db_name], request)
        return request.db[db_name]

    if debug:
        config.registry.settings['debugtoolbar.extra_panels'].append(MongoToolbar)
        config.add_request_method(add_query_log, 'query_log', reify=True)
    config.add_request_method(add_db_conn, 'db', reify=True)
    mongo_dbs = config.registry.settings.get('mongo_dbs')
    if mongo_dbs is None:
        raise ValueError("Please set at least 1 database name in mongo_dbs in your configuration")

    def make_get_db(**kwargs):
        def get_db(request):
            return get_database(request, kwargs['db_name'])

        return get_db

    for db_name in mongo_dbs.splitlines():
        if '=' in db_name or ':' in db_name:
            db_name, nice_name = (x.strip() for x in re.split(r'[=:]', db_name))
        else:
            nice_name = db_name
        fun = make_get_db(db_name=db_name)

        config.add_request_method(fun, 'db_' + nice_name.replace('-', '_'), reify=True)
    config.scan(__name__)
