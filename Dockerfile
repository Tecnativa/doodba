FROM debian:8
MAINTAINER Tecnativa <info@tecnativa.com>

# Enable Odoo user and filestore
RUN useradd -md /opt/odoo odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo
VOLUME ["/var/lib/odoo"]
EXPOSE 8069 8072

# Subimage triggers
ONBUILD ARG AGGREGATE=true
ONBUILD ARG DEPTH_DEFAULT=1
ONBUILD ARG DEPTH_MERGE=100
ONBUILD ARG CLEAN=true
ONBUILD ARG COMPILE=true
ONBUILD ARG LINK=true
ONBUILD ARG PIP_INSTALL_ODOO=true
ONBUILD ARG ADMIN_PASSWORD=admin
ONBUILD ARG SMTP_SERVER=smtp
ONBUILD ARG PROXY_MODE=false
ONBUILD ARG WITHOUT_DEMO=all
ONBUILD ARG PYTHONOPTIMIZE=1
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
ENV OPENERP_SERVER=/opt/odoo/auto/odoo.conf \
    UNACCENT=true \
    # Git and git-aggregator
    GIT_AUTHOR_NAME=docker-odoo \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    DEPTH_DEFAULT=1 \
    DEPTH_MERGE=100 \
    # Postgres
    WAIT_DB=true \
    # PuDB debugger
    PUDB_RDB_HOST=0.0.0.0 \
    PUDB_RDB_PORT=6899 \
    # WDB debugger
    WDB_NO_BROWSER_AUTO_OPEN=True \
    WDB_SOCKET_SERVER=wdb \
    WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost \
    # Other
    LC_ALL=C.UTF-8

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        # Odoo direct dependencies
        python ruby-compass node-less \
        # Odoo indirect dependencies
        libxml2 libxslt1.1 libjpeg62-turbo zlib1g libfreetype6 liblcms2-2 \
        libopenjpeg5 libtiff5 tk tcl libpq5 libldap-2.4-2 libsasl2-2 \
        # This image's facilities
        bzip2 curl gettext-base git nano npm openssh-client telnet \
    && curl https://bootstrap.pypa.io/get-pip.py | python /dev/stdin --no-cache-dir \

    # Special case to get latest PostgreSQL client
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \

    # Special case for PhantomJS
    && ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g phantomjs-prebuilt \
    && rm -Rf ~/.npm \

    # Special case for wkhtmltox
    && curl -SLo wkhtmltox.deb https://nightly.odoo.com/extra/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb \
    && echo "4ec2aa2a13d6127cdd6ca07ab18b807a6c5c1f5215c5880b951a89642c1a0ecd  wkhtmltox.deb" | sha256sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get -y purge curl \
    && apt-get -y autoremove \
    && rm -Rf /var/lib/apt/lists/* wkhtmltox.deb

# Other facilities
RUN pip install --no-cache-dir \
    astor git-aggregator openupgradelib pudb wdb
COPY bin/autoaggregate bin/log bin/pot bin/unittest bin/install.sh /usr/local/bin/
COPY bin/direxec.sh /opt/odoo/common/entrypoint.sh
RUN ln /opt/odoo/common/entrypoint.sh /opt/odoo/common/build.sh
COPY lib/*.py /usr/local/lib/python2.7/dist-packages
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
