# The version you are building
ARG ODOO_VERSION=11.0

# Common base images
FROM debian:9 as python3

# Enable Odoo user and filestore
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo \
    && sync
VOLUME ["/var/lib/odoo"]
EXPOSE 8069 8072

ARG WKHTMLTOPDF_VERSION=0.12.4
ARG WKHTMLTOPDF_CHECKSUM='049b2cdec9a8254f0ef8ac273afaf54f7e25459a273e27189591edc7d7cf29db'
ENV DEPTH_DEFAULT=1 \
    DEPTH_MERGE=100 \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    GIT_AUTHOR_NAME=docker-odoo \
    LC_ALL=C.UTF-8 \
    NODE_PATH=/usr/local/lib/node_modules:/usr/lib/node_modules \
    OPENERP_SERVER=/opt/odoo/auto/odoo.conf \
    PATH="~/.local/bin:$PATH" \
    PUDB_RDB_HOST=0.0.0.0 \
    PUDB_RDB_PORT=6899 \
    UNACCENT=true \
    WAIT_DB=true \
    WDB_NO_BROWSER_AUTO_OPEN=True \
    WDB_SOCKET_SERVER=wdb \
    WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apt-get -qq update \
    && apt-get -yqq upgrade \
    && apt-get install -yqq --no-install-recommends \
        python3 ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        libfreetype6 liblcms2-2 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git gnupg2 nano \
        openssh-client postgresql-client telnet xz-utils \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 /dev/stdin --no-cache-dir \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -yqq nodejs \
    && apt-get -yqq purge python2.7 \
    && apt-get -yqq autoremove \
    && rm -Rf /var/lib/apt/lists/*

# Special case to get latest Less and PhantomJS
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less phantomjs-prebuilt \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<4' \
    && rm -Rf ~/.gem /var/lib/gems/*/cache/

# Special case for wkhtmltox
RUN curl -SLo wkhtmltox.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.tar.xz" | sha256sum -c - \
    && tar --strip-components 1 -C /usr/local/ -xf wkhtmltox.tar.xz \
    && rm wkhtmltox.tar.xz \
    && wkhtmltopdf --version
# Other facilities
WORKDIR /opt/odoo
RUN pip install --no-cache-dir \
    astor git-aggregator openupgradelib ptvsd==3.0.0 pudb wdb
COPY bin/* /usr/local/bin/
COPY lib/odoobaselib /usr/local/lib/python3.5/dist-packages/odoobaselib
COPY build.d common/build.d
COPY conf.d common/conf.d
COPY entrypoint.d common/entrypoint.d
RUN mkdir -p auto/addons custom/src/private \
    && ln /usr/local/bin/direxec common/entrypoint \
    && ln /usr/local/bin/direxec common/build \
    && chmod -R a+rx common/entrypoint* common/build* /usr/local/bin \
    && chmod -R a+rX /usr/local/lib/python3.5/dist-packages/odoobaselib \
    && ln -s $(which python3) /usr/local/bin/python \
    && sync

# Metadata
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.label-schema.vendor=Tecnativa \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/Tecnativa/docker-odoo-base"

FROM debian:8 as python2

# Enable Odoo user and filestore
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo \
    && sync
VOLUME ["/var/lib/odoo"]
EXPOSE 8069 8072

ARG WKHTMLTOPDF_VERSION=0.12.4
ARG WKHTMLTOPDF_CHECKSUM='049b2cdec9a8254f0ef8ac273afaf54f7e25459a273e27189591edc7d7cf29db'
ENV DEPTH_DEFAULT=1 \
    DEPTH_MERGE=100 \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    GIT_AUTHOR_NAME=docker-odoo \
    LC_ALL=C.UTF-8 \
    OPENERP_SERVER=/opt/odoo/auto/odoo.conf \
    PATH="~/.local/bin:$PATH" \
    PUDB_RDB_HOST=0.0.0.0 \
    PUDB_RDB_PORT=6899 \
    UNACCENT=true \
    WAIT_DB=true \
    WDB_NO_BROWSER_AUTO_OPEN=True \
    WDB_SOCKET_SERVER=wdb \
    WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        python ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        libfreetype6 liblcms2-2 libopenjpeg5 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git nano npm \
        openssh-client telnet xz-utils \
    && curl https://bootstrap.pypa.io/get-pip.py | python /dev/stdin --no-cache-dir \
    && rm -Rf /var/lib/apt/lists/*

# Make node find --global addons
ENV NODE_PATH=/usr/local/lib/node_modules

# Special case to get latest PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Special case to get latest Less
RUN npm install -g less \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<4' \
    && rm -Rf ~/.gem /var/lib/gems/*/cache/

# Special case for PhantomJS
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g phantomjs-prebuilt \
    && rm -Rf ~/.npm /tmp/*

# Special case for wkhtmltox
RUN curl -SLo wkhtmltox.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.tar.xz" | sha256sum -c - \
    && tar --strip-components 1 -C /usr/local/ -xf wkhtmltox.tar.xz \
    && rm wkhtmltox.tar.xz \
    && wkhtmltopdf --version

# Other facilities
WORKDIR /opt/odoo
RUN pip install --no-cache-dir \
    astor git-aggregator openupgradelib ptvsd==3.0.0 pudb wdb
COPY bin/* /usr/local/bin/
COPY lib/odoobaselib /usr/local/lib/python2.7/dist-packages/odoobaselib
COPY build.d common/build.d
COPY conf.d common/conf.d
COPY entrypoint.d common/entrypoint.d
RUN mkdir -p auto/addons custom/src/private \
    && ln /usr/local/bin/direxec common/entrypoint \
    && ln /usr/local/bin/direxec common/build \
    && chmod -R a+rx common/entrypoint* common/build* /usr/local/bin \
    && chmod -R a+rX /usr/local/lib/python2.7/dist-packages/odoobaselib \
    && sync

# Specific version images
FROM python2 as odoo-8.0
ARG ODOO_SOURCE=OCA/OCB
ENV ODOO_VERSION=8.0
LABEL org.label-schema.schema-version="$ODOO_VERSION"
RUN apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends \
        build-essential \
        libfreetype6-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjpeg-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libxml2-dev \
        libxslt1-dev \
        linux-headers-amd64 \
        python-dev \
        tcl-dev \
        tk-dev \
    && curl -SL https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        | sed -r 's/pyparsing|six|psycopg2/#\0/' \
        | pip install --no-cache-dir -r /dev/stdin 'psycopg2>=2.7' \
    && python -OO -m compileall -q /usr/local/lib/python2.7/ || true \
    && apt-get purge -yqq build-essential '*-dev' \
    && apt-mark -qq manual '*' \
    && rm -Rf /var/lib/apt/lists/*

FROM python2 as odoo-9.0
ARG ODOO_SOURCE=OCA/OCB
ENV ODOO_VERSION=9.0
LABEL org.label-schema.schema-version="$ODOO_VERSION"
RUN apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends \
        build-essential \
        libfreetype6-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjpeg-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libxml2-dev \
        libxslt1-dev \
        linux-headers-amd64 \
        python-dev \
        tcl-dev \
        tk-dev \
    && curl -SL https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        | sed -r 's/psycopg2/#\0/' \
        | pip install --no-cache-dir -r /dev/stdin 'psycopg2>=2.7' \
    && python -OO -m compileall -q /usr/local/lib/python2.7/ || true \
    && apt-get purge -yqq build-essential '*-dev' \
    && apt-mark -qq manual '*' \

FROM python2 as odoo-10.0
ARG ODOO_SOURCE=OCA/OCB
ENV ODOO_VERSION=10.0
LABEL org.label-schema.schema-version="$ODOO_VERSION"
RUN apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends \
        build-essential \
        libfreetype6-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjpeg-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libxml2-dev \
        libxslt1-dev \
        linux-headers-amd64 \
        python-dev \
        tcl-dev \
        tk-dev \
    && curl -SL https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        | sed -r 's/psycopg2/#\0/' \
        | pip install --no-cache-dir -r /dev/stdin 'psycopg2>=2.7' \
    && python -OO -m compileall -q /usr/local/lib/python2.7/ || true \
    && apt-get purge -yqq build-essential '*-dev' \
    && apt-mark -qq manual '*' \

FROM python3 as odoo-11.0
ARG ODOO_SOURCE=OCA/OCB
ENV ODOO_VERSION=11.0
LABEL org.label-schema.schema-version="$ODOO_VERSION"
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libevent-dev \
        libjpeg-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        python3-dev \
        zlib1g-dev \
    && pip install --no-cache-dir -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
    && python3 -OO -m compileall -q /usr/local/lib/python3.5/ || true \
    && apt-get purge -yqq build-essential '*-dev' \
    && apt-mark -qq manual '*' \
    && rm -Rf /var/lib/apt/lists/*

# Subimage triggers, common to all versions
FROM odoo-${ODOO_VERSION} as odoo-onbuild
ONBUILD ENTRYPOINT ["/opt/odoo/common/entrypoint"]
ONBUILD CMD ["/usr/local/bin/odoo"]
ONBUILD ARG AGGREGATE=true
ONBUILD ARG DEPTH_DEFAULT=1
ONBUILD ARG DEPTH_MERGE=100
ONBUILD ARG CLEAN=true
ONBUILD ARG COMPILE=true
ONBUILD ARG CONFIG_BUILD=true
ONBUILD ARG PIP_INSTALL_ODOO=true
ONBUILD ARG ADMIN_PASSWORD=admin
ONBUILD ARG SMTP_SERVER=smtp
ONBUILD ARG PROXY_MODE=false
ONBUILD ARG WITHOUT_DEMO=all
ONBUILD ARG PGUSER=odoo
ONBUILD ARG PGPASSWORD=odoopassword
ONBUILD ARG PGHOST=db
ONBUILD ARG PGDATABASE=prod
# Config variables
ONBUILD ENV ADMIN_PASSWORD="$ADMIN_PASSWORD" \
            UNACCENT="$UNACCENT" \
            PGUSER="$PGUSER" \
            PGPASSWORD="$PGPASSWORD" \
            PGHOST="$PGHOST" \
            PGDATABASE="$PGDATABASE" \
            PROXY_MODE="$PROXY_MODE" \
            SMTP_SERVER="$SMTP_SERVER" \
            WITHOUT_DEMO="$WITHOUT_DEMO"
ONBUILD ARG LOCAL_CUSTOM_DIR=./custom
ONBUILD COPY $LOCAL_CUSTOM_DIR /opt/odoo/custom
# https://docs.python.org/2.7/library/logging.html#levels
ONBUILD ARG LOG_LEVEL=INFO
ONBUILD RUN mkdir -p /opt/odoo/custom/ssh \
            && ln -s /opt/odoo/custom/ssh ~root/.ssh \
            && chmod -R u=rwX,go= /opt/odoo/custom/ssh \
            && sync
ONBUILD RUN ["/opt/odoo/common/build"]
ONBUILD USER odoo
