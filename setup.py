from setuptools import setup
import os


def readfile(name):
    with open(name) as f:
        return f.read()


def get_version(pkg_name):
    """
    Reads the version string from the package __init__ and returns it
    """
    with open(os.path.join(pkg_name, "__init__.py")) as init_file:
        for line in init_file:
            parts = line.strip().partition("=")
            if parts[0].strip() == "__version__":
                return parts[2].strip().strip("'").strip('"')
    return None

README = readfile('README.md')

install_requires = [
    'pyramid',
    'pyramid-debugtoolbar',
    'pymongo',
]

testing_extras = [
    'WebTest',
    'nose',
    'coverage',
]

setup(name='pyramid_mongodb2',
      version=get_version('pyramid_mongodb2'),
      description=('An improved package that provides mongodb connectivity.'
                   'Not compatible with pyramid_mongo or pyramid_mongodb'),
      long_description=README,
      long_description_content_type="text/markdown",
      classifiers=[
          "Intended Audience :: Developers",
          "Programming Language :: Python",
          "Programming Language :: Python :: 3",
          "Programming Language :: Python :: 3.3",
          "Programming Language :: Python :: 3.4",
          "Programming Language :: Python :: 3.5",
          "Programming Language :: Python :: 3.6",
          "Programming Language :: Python :: 3.7",
          "Programming Language :: Python :: 3.8",
          "Framework :: Pyramid",
          "Topic :: Internet :: WWW/HTTP :: WSGI",
          "License :: OSI Approved :: MIT License",
      ],
      keywords='wsgi pylons pyramid mongodb pymongo',
      author="Jonathan Mackenzie",
      author_email="pylons-discuss@googlegroups.com",
      url="https://github.com/jonnoftw/pyramid_mongodb2",
      license="MIT",
      packages = ['pyramid_mongodb2'],
      include_package_data=True,
      package_data = {
          'pyramid_mongodb2': ['templates/*.mako']
      },
      zip_safe=False,
      install_requires=install_requires,
      extras_require={
          'testing': testing_extras,
      },
      test_suite="tests",
      )
