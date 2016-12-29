FROM python:2-alpine
MAINTAINER Tecnativa <info@tecnativa.com>

# Enable Odoo user and filestore
RUN adduser -D odoo \
    && mkdir -p /home/odoo/.local/share/Odoo \
    && chown -R odoo:odoo /home/odoo
VOLUME ["/home/odoo/.local/share/Odoo"]
EXPOSE 8069 8072

# Subimage triggers
ONBUILD ARG AGGREGATE=yes
ONBUILD ARG CLEAN=yes
ONBUILD ARG COMPILE=yes
ONBUILD ARG LOCAL_CUSTOM_DIR=./custom
ONBUILD COPY $LOCAL_CUSTOM_DIR /opt/odoo/custom
ONBUILD WORKDIR /opt/odoo
ONBUILD RUN chown -R odoo:odoo .
ONBUILD RUN ["/opt/odoo/common/build.sh"]
ONBUILD ENTRYPOINT ["/opt/odoo/common/entrypoint.sh"]
ONBUILD CMD ["/usr/local/bin/odoo.py"]
ONBUILD USER odoo

ENV ODOO_VERSION=9.0 \
    ODOO_SOURCE=OCA/OCB \
    ODOO_RC=/opt/odoo/auto/odoo.conf \
    ADMIN_PASSWORD=admin \
    PROXY_MODE=yes \
    SMTP_SERVER=smtp \
    UNACCENT=yes \
    PYTHONOPTIMIZE=2 \
    # HACK for Pillow: https://github.com/Tecnativa/odoo/pull/1
    CFLAGS="-L/lib" \
    # Git and git-aggregator
    GIT_AUTHOR_NAME=docker-odoo \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    # Postgres
    WAIT_DB=yes \
    PGUSER=odoo \
    PGPASSWORD=odoopassword \
    PGHOST=db \
    PGDATABASE=odooproduction \
    # WDB debugger
    WDB_NO_BROWSER_AUTO_OPEN=True \
    WDB_SOCKET_SERVER=wdb \
    WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apk add --no-cache \
        ghostscript icu libev nodejs openssl \
        postgresql-libs poppler-utils ruby
# Special case for wkhtmltox
# HACK https://github.com/wkhtmltopdf/wkhtmltopdf/issues/3265
# Idea from https://hub.docker.com/r/loicmahieu/alpine-wkhtmltopdf/
# Use prepackaged wkhtmltopdf and wrap it with a dummy X server
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing wkhtmltopdf
RUN apk add --no-cache xvfb ttf-dejavu ttf-freefont fontconfig dbus
COPY bin/wkhtmltox.sh /usr/local/bin/wkhtmltoimage
RUN ln /usr/local/bin/wkhtmltoimage /usr/local/bin/wkhtmltopdf

# Requirements to build Odoo dependencies
RUN apk add --no-cache --virtual .build-deps \
    # Common to all Python packages
    build-base python-dev \
    # lxml
    libxml2-dev libxslt-dev \
    # Pillow
    jpeg-dev zlib-dev freetype-dev lcms2-dev openjpeg-dev \
    tiff-dev tk-dev tcl-dev \
    # psutil
    linux-headers \
    # psycopg2
    postgresql-dev \
    # python-ldap
    openldap-dev \
    # Sass, compass
    ruby-dev libffi-dev \

    # CSS preprocessors
    && gem install --clear-sources --no-document sass \
    && npm install --global less \
    && npm cache clean \

    # Build and install Odoo dependencies with pip
    # HACK Some modules cannot be installed with PYTHONOPTIMIZE=2
    && PYTHONOPTIMIZE=1 pip install --no-cache-dir \
        # HACK https://github.com/giampaolo/psutil/issues/948
        # TODO Remove in psutil>=5.0.2
        psutil==2.2.0 \
        # HACK https://github.com/erocarrera/pydot/issues/145
        pydot==1.0.2 \
        # HACK https://github.com/psycopg/psycopg2/commit/37d80f2c0325951d3ee6b07caf7d343d4a97a23d
        # TODO Remove in psycopg2>=2.6
        psycopg2==2.5.4 \
        # HACK https://github.com/eventable/vobject/pull/19
        # TODO Remove in vobject>=0.9.3
        vobject==0.6.6 \
    && pip install --no-cache-dir --requirement https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \

    # Remove all installed garbage
    && apk del .build-deps

# Patched git-aggregator
RUN pip install --no-cache-dir https://github.com/Tecnativa/git-aggregator/archive/master-depth.zip
# HACK Install git >= 2.11, to have --shallow-since
# TODO Remove HACK when python:2-alpine is alpine >= v3.5
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.5/main git

# WDB debugger
RUN pip install --no-cache-dir wdb

# Other facilities
RUN apk add --no-cache gettext postgresql-client
RUN pip install --no-cache-dir openupgradelib
COPY bin/log bin/unittest /usr/local/bin/
COPY bin/direxec.sh /opt/odoo/common/entrypoint.sh
RUN ln /opt/odoo/common/entrypoint.sh /opt/odoo/common/build.sh
COPY build.d /opt/odoo/common/build.d
COPY conf.d /opt/odoo/common/conf.d
COPY entrypoint.d /opt/odoo/common/entrypoint.d
