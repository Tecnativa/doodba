#!/bin/bash
set -ex

reqs=https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt
apt_deps="python-dev build-essential"
apt-get update

# lxml
apt_deps="$apt_deps libxml2-dev libxslt1-dev"
# Pillow
apt_deps="$apt_deps libjpeg-dev libfreetype6-dev
    liblcms2-dev libopenjpeg-dev libtiff5-dev tk-dev tcl-dev"
# psutil
apt_deps="$apt_deps linux-headers-amd64"
# psycopg2
apt_deps="$apt_deps libpq-dev"
# python-ldap
apt_deps="$apt_deps libldap2-dev libsasl2-dev"

apt-get install -y --no-install-recommends $apt_deps

# Install all dependencies that do not support PYTHONOPTIMIZE=2
# TODO Remove when these get fixed:
# https://github.com/Tecnativa/docker-odoo-base/issues/18

# Download requirements file to be able to patch it
curl -SLo /tmp/requirements.txt $reqs
reqs=/tmp/requirements.txt
# https://github.com/Tecnativa/docker-odoo-base/issues/21
if [ "$ODOO_VERSION" == "8.0" ]; then
    # Packages already installed that conflict with others
    sed -ir 's/pyparsing|six/#\0/' $reqs
    pip_deps="psutil==2.1.1 pydot==1.0.2 vobject==0.6.6"
    # Extra dependencies for Odoo at runtime
    apt-get install -y --no-install-recommends file
elif [ "$ODOO_VERSION" == "9.0" ]; then
    pip_deps="psutil==2.2.0 pydot==1.0.2 vobject==0.6.6"
else
    pip_deps="psutil==4.3.1 pydot==1.2.3"
fi

# psycopg2 will be installed later
sed -ir 's/psycopg2/#\0/' $reqs

optimize="$PYTHONOPTIMIZE"
if [ $PYTHONOPTIMIZE -gt 1 ]; then
    export PYTHONOPTIMIZE=1
fi
pip install --no-cache-dir $pip_deps
export PYTHONOPTIMIZE="$optimize"

# Security upgrades
pip install --no-cache-dir "psycopg2>=2.7" # ODOO-SA-2017-06-15-1

# Build and install Odoo dependencies with pip
pip install --no-cache-dir --requirement $reqs

# Remove all installed garbage
apt-get -y purge $apt_deps
apt-get -y autoremove
rm -Rf /var/lib/apt/lists/* /tmp/* || true
