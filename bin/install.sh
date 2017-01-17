#!/bin/sh
set -ex

# Requirements to build Odoo dependencies
apk add --no-cache --virtual .common-deps build-base python-dev
# lxml
apk add --no-cache --virtual .lxml-deps libxml2-dev libxslt-dev
# Pillow
apk add --no-cache --virtual .pillow-deps \
    jpeg-dev zlib-dev freetype-dev lcms2-dev openjpeg-dev \
    tiff-dev tk-dev tcl-dev
# psutil
apk add --no-cache --virtual .psutil-deps linux-headers
# psycopg2
apk add --no-cache --virtual .psycopg2-deps postgresql-dev
# python-ldap
apk add --no-cache --virtual .python-ldap-deps openldap-dev
# Sass
apk add --no-cache --virtual .sass-deps ruby-dev libffi-dev

# CSS preprocessors
gem install --clear-sources --no-document sass
npm install --global less
npm cache clean
rm -Rf /tmp/*

# Build and install Odoo dependencies with pip
# TODO Remove in psutil>=5.0.2
# HACK https://github.com/giampaolo/psutil/issues/948
deps="$deps psutil==2.2.0"
# HACK https://github.com/erocarrera/pydot/issues/145
deps="$deps pydot==1.0.2"
# TODO Remove in psycopg2>=2.6
# HACK https://github.com/psycopg/psycopg2/commit/37d80f2c0325951d3ee6b07caf7d343d4a97a23d
deps="$deps psycopg2==2.5.4"
# TODO Remove in vobject>=0.9.3
# HACK https://github.com/eventable/vobject/pull/19
deps="$deps vobject==0.6.6"

# TODO Remove when all of above deps support PYTHONOPTIMIZE=2
optimize="$PYTHONOPTIMIZE"
if [ $PYTHONOPTIMIZE -gt 1 ]; then
    export PYTHONOPTIMIZE=1
fi
pip install --no-cache-dir $deps
export PYTHONOPTIMIZE="$optimize"

pip install --no-cache-dir --requirement https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt

# Remove all installed garbage
apk del .common-deps .lxml-deps .pillow-deps .psutil-deps .psycopg2-deps \
    .python-ldap-deps .sass-deps
