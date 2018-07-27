Pyramid Mongodb
===============

A simple library to integrate mongodb into your pyramid application. Integrates with [pyramid_mongodb2_debugtoolbar](https://pypi.org/project/pyramid_mongodb2_debugtoolbar/).

Features
--------

* Supports multiple databases
* Configuration only setup
* Integrated debugtoolbar
* Avoids recreating and closing `MongoClient` on every request. 

Setup
-----
```bash
pip install pyramid_mongodb 
```

Add the following to your application's ini file, (include `pyramid_mongodb2_debugtoolbar` if you want to debug):

```ini
[app:main]
mongo_uri = mongodb://username:password@mongodb.host.com:27017/authdb
mongo_db = 
    foo
    bar
pyramid.includes =
    pyramid_mako    
    pyramid_debugtoolbar
    pyramid_mongodb2
    pyramid_mongodb2_debugtoolbar
debugtoolbar.includes =
    pyramid_mongodb2_debugtoolbar:MongoToolbar
```
The code will use `config.add_request_method()` to add a `Database` object to your requests, where each database is accessable by `db_database_name`, as defined in your configuration. 
In your code where you can access `request`, you now have the following variables:

```python
request.db
request.db_foo
request.db_bar
```
`request.db` is the `MongoClient` object, should you ever need it.

In your view code, you can do this:

```python
from pyramid.view import view_config

@view_config(route_name='home', renderer="templates/landing.mako")
def my_view(request):
    return {
        'some_data': request.db_foo.some_collection.find({'a': {'$gte': 5}}, {'_id': False}),
        'other_data': request.db_bar.visitors.insert_one({'person': request.remote_addr}),
    }
```