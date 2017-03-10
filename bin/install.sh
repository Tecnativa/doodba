#!/bin/bash
set -ex

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

# Build and install Odoo dependencies with pip
if [ "$ODOO_VERSION" == "9.0" ]; then
    # TODO Remove in psutil>=5.0.2
    # HACK https://github.com/giampaolo/psutil/issues/948
    pip_deps="$pip_deps psutil==2.2.0"
    # TODO Remove in version that fixes it
    # HACK https://github.com/erocarrera/pydot/issues/145
    pip_deps="$pip_deps pydot==1.0.2"
    # TODO Remove in psycopg2>=2.6
    # HACK https://github.com/psycopg/psycopg2/commit/37d80f2c0325951d3ee6b07caf7d343d4a97a23d
    pip_deps="$pip_deps psycopg2==2.5.4"
    # TODO Remove in vobject>=0.9.3
    # HACK https://github.com/eventable/vobject/pull/19
    pip_deps="$pip_deps vobject==0.6.6"
elif [ "$ODOO_VERSION" == "10.0" ]; then
    # TODO Remove in psutil>=5.0.2
    # HACK https://github.com/giampaolo/psutil/issues/948
    pip_deps="$pip_deps psutil==4.3.1"
    # TODO Remove in version that fixes it
    # HACK https://github.com/erocarrera/pydot/issues/145
    pip_deps="$pip_deps pydot==1.2.3"
fi

# TODO Remove when all of above pip_deps support PYTHONOPTIMIZE=2
optimize="$PYTHONOPTIMIZE"
if [ $PYTHONOPTIMIZE -gt 1 ]; then
    export PYTHONOPTIMIZE=1
fi
pip install --no-cache-dir $pip_deps
export PYTHONOPTIMIZE="$optimize"

pip install --no-cache-dir --requirement https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt

# Remove all installed garbage
apt-get -y purge $apt_deps
apt-get -y autoremove
rm -Rf /var/lib/apt/lists/*
