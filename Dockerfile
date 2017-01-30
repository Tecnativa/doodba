FROM python:2-alpine
MAINTAINER Tecnativa <info@tecnativa.com>

# Enable Odoo user and filestore
RUN adduser -DH odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo
VOLUME ["/var/lib/odoo"]
EXPOSE 8069 8072

# Subimage triggers
ONBUILD ARG AGGREGATE=yes
ONBUILD ARG CLEAN=yes
ONBUILD ARG COMPILE=yes
ONBUILD ARG PIP_INSTALL_ODOO=yes
ONBUILD ARG ADMIN_PASSWORD=admin
ONBUILD ARG SMTP_SERVER=smtp
ONBUILD ARG PROXY_MODE=no
ONBUILD ARG WITHOUT_DEMO=all
ONBUILD ARG PYTHONOPTIMIZE=2
ONBUILD ENV PYTHONOPTIMIZE="$PYTHONOPTIMIZE"
ONBUILD ARG PGUSER=odoo
ONBUILD ARG PGPASSWORD=odoopassword
ONBUILD ARG PGHOST=db
ONBUILD ARG PGDATABASE=prod
ONBUILD ENV PGUSER="$PGUSER" \
            PGPASSWORD="$PGPASSWORD" \
            PGHOST="$PGHOST" \
            PGDATABASE="$PGDATABASE"
ONBUILD ARG LOCAL_CUSTOM_DIR=./custom
ONBUILD COPY $LOCAL_CUSTOM_DIR /opt/odoo/custom
ONBUILD WORKDIR /opt/odoo
ONBUILD RUN chown -R odoo:odoo . \
    && chmod -Rc a+rx common/entrypoint.d common/build.d
# https://docs.python.org/2.7/library/logging.html#levels
ONBUILD ARG LOG_LEVEL=20
ONBUILD RUN ["/opt/odoo/common/build.sh"]
ONBUILD ENTRYPOINT ["/opt/odoo/common/entrypoint.sh"]
ONBUILD CMD ["/usr/local/bin/odoo"]
ONBUILD USER odoo

ARG PYTHONOPTIMIZE=2
ENV ODOO_RC=/opt/odoo/auto/odoo.conf \
    UNACCENT=yes \
    # HACK for Pillow: https://github.com/Tecnativa/odoo/pull/1
    LDFLAGS="-L/usr/local/lib -L/usr/lib -L/lib" \
    # Git and git-aggregator
    GIT_AUTHOR_NAME=docker-odoo \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    # Postgres
    WAIT_DB=yes \
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

# Patched git-aggregator
RUN apk add --no-cache git
RUN pip install --no-cache-dir https://github.com/acsone/git-aggregator/archive/bdfdf05a7e903b06c201f163161053a924330bed.zip

# WDB debugger
RUN pip install --no-cache-dir wdb

# Other facilities
RUN apk add --no-cache gettext postgresql-client
RUN pip install --no-cache-dir openupgradelib
COPY bin/log bin/unittest bin/install.sh /usr/local/bin/
COPY bin/direxec.sh /opt/odoo/common/entrypoint.sh
RUN ln /opt/odoo/common/entrypoint.sh /opt/odoo/common/build.sh
COPY lib/*.py /usr/local/lib/python2.7/site-packages
COPY build.d /opt/odoo/common/build.d
COPY conf.d /opt/odoo/common/conf.d
COPY entrypoint.d /opt/odoo/common/entrypoint.d
RUN mkdir -p /opt/odoo/auto/addons
RUN chmod -Rc a+rx \
    /opt/odoo/common/entrypoint* \
    /opt/odoo/common/build* \
    /usr/local/bin

# Execute installation script by Odoo version
# This is at the end to benefit from cache at build time
# https://docs.docker.com/engine/reference/builder/#/impact-on-build-caching
ARG ODOO_SOURCE=OCA/OCB
ARG ODOO_VERSION=10.0
ENV ODOO_VERSION="$ODOO_VERSION"
RUN install.sh

# Metadata
ARG VCS_REF
ARG BUILD_DATE
LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor=Tecnativa \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/Tecnativa/docker-odoo-base"
