FROM debian:buster AS builder
RUN sed -i 's,http://deb.debian.org,http://archive.debian.org,g;s,http://security.debian.org,http://archive.debian.org,g' /etc/apt/sources.list

ARG TARGETARCH
ARG ODOO_VERSION=13.0
ARG OPENSSL_VERSION=3.5.1
ARG CURL_VERSION=8.14.1
ARG GIT_VERSION=2.47.3

RUN --mount=target=/var/lib/apt/lists,type=cache,id=apt-lists-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/var/cache/apt,type=cache,id=apt-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/tmp,type=tmpfs \
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        autoconf automake libtool pkg-config \
        libssl-dev zlib1g-dev libpsl-dev \
        libcurl4-openssl-dev libexpat1-dev \
        gettext libz-dev \
        wget ca-certificates

WORKDIR /usr/src

# --- Download all sources (cached independently, survives layer-cache misses) ---
RUN --mount=type=cache,target=/root/.cache/dl,id=src-downloads-${TARGETARCH},sharing=locked \
    set -eux; \
    OPENSSL_TARBALL="openssl-${OPENSSL_VERSION}.tar.gz"; \
    CURL_TARBALL="curl-${CURL_VERSION}.tar.gz"; \
    GIT_TARBALL="v${GIT_VERSION}.tar.gz"; \
    [ -f "/root/.cache/dl/${OPENSSL_TARBALL}" ] || wget -q -O "/root/.cache/dl/${OPENSSL_TARBALL}" \
        "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/${OPENSSL_TARBALL}"; \
    [ -f "/root/.cache/dl/${CURL_TARBALL}" ] || wget -q -O "/root/.cache/dl/${CURL_TARBALL}" \
        "https://curl.se/download/${CURL_TARBALL}"; \
    [ -f "/root/.cache/dl/${GIT_TARBALL}" ] || wget -q -O "/root/.cache/dl/${GIT_TARBALL}" \
        "https://github.com/git/git/archive/refs/tags/${GIT_TARBALL}"; \
    cp "/root/.cache/dl/${OPENSSL_TARBALL}" /usr/src/; \
    cp "/root/.cache/dl/${CURL_TARBALL}" /usr/src/; \
    cp "/root/.cache/dl/${GIT_TARBALL}" /usr/src/; \
    tar xzf "${OPENSSL_TARBALL}"; \
    tar xzf "${CURL_TARBALL}"; \
    tar xzf "${GIT_TARBALL}"

# --- Build OpenSSL 3.x (own layer, static, isolated prefix) ---
RUN cd openssl-${OPENSSL_VERSION} \
    && ./Configure --prefix=/opt/openssl --openssldir=/opt/openssl/ssl \
        no-shared no-tests \
        linux-$([ "$TARGETARCH" = "arm64" ] && echo aarch64 || echo x86_64) \
    && make -j"$(nproc)" \
    && make install_sw install_ssldirs

# --- Build curl against the freshly built OpenSSL (own layer) ---
RUN cd curl-${CURL_VERSION} \
    && ./configure --prefix=/usr/local \
        --with-openssl=/opt/openssl \
        --enable-ipv6 \
    && make -j"$(nproc)" \
    && make install \
    && make install DESTDIR=/build/curl

# --- Build git (own layer) ---
RUN cd git-${GIT_VERSION} \
    && make configure \
    && ./configure --prefix=/usr/local \
    && make -j"$(nproc)" all \
    && make install DESTDIR=/build/git
FROM python:3.6-slim-buster AS base
ARG ODOO_VERSION=13.0
ENV ODOO_VERSION="$ODOO_VERSION"
EXPOSE 8069 8072
ARG TARGETARCH
ARG GEOIP_UPDATER_VERSION=4.1.5
ARG MQT=https://github.com/OCA/maintainer-quality-tools.git
ARG WKHTMLTOPDF_VERSION=0.12.5
ARG WKHTMLTOPDF_CHECKSUM='dfab5506104447eef2530d1adb9840ee3a67f30caaad5e9bcb8743ef2f9421bd'
ENV DB_FILTER=.* \
    DEPTH_DEFAULT=1 \
    DEPTH_MERGE=100 \
    EMAIL=https://hub.docker.com/r/tecnativa/odoo \
    GEOIP_ACCOUNT_ID="" \
    GEOIP_LICENSE_KEY="" \
    GIT_AUTHOR_NAME=docker-odoo \
    INITIAL_LANG="" \
    LC_ALL=C.UTF-8 \
    LIST_DB=false \
    NODE_PATH=/usr/local/lib/node_modules:/usr/lib/node_modules \
    OPENERP_SERVER=/opt/odoo/auto/odoo.conf \
    PATH="/home/odoo/.local/bin:$PATH" \
    PTVSD_ARGS="--host 0.0.0.0 --port 6899 --wait --multiprocess" \
    PTVSD_ENABLE=0 \
    DEBUGPY_ARGS="--listen 0.0.0.0:6899 --wait-for-client" \
    DEBUGPY_ENABLE=0 \
    PUDB_RDB_HOST=0.0.0.0 \
    PUDB_RDB_PORT=6899 \
    PYTHONOPTIMIZE="" \
    UNACCENT=true \
    WAIT_DB=true \
    WDB_NO_BROWSER_AUTO_OPEN=True \
    WDB_SOCKET_SERVER=wdb \
    WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost
COPY --from=builder /build/curl/usr/local /usr/local
COPY --from=builder /build/git/usr/local /usr/local

# Debian buster was moved to archive
RUN sed -i 's,http://deb.debian.org,http://archive.debian.org,g;s,http://security.debian.org,http://archive.debian.org,g' /etc/apt/sources.list
# Other requirements and recommendations
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN --mount=target=/var/lib/apt/lists,type=cache,id=apt-lists-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/var/cache/apt,type=cache,id=apt-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/tmp,type=tmpfs \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && ldconfig \
    && apt-get -qq update \
    && apt-get install -yqq --no-install-recommends \
        zlib1g libpsl5 libexpat1 ca-certificates \
    && curl -SLo /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.buster_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM} /tmp/wkhtmltox.deb" | sha256sum -c - \
    && apt-get install -yqq --no-install-recommends \
        /tmp/wkhtmltox.deb \
        chromium \
        ffmpeg \
        fonts-liberation2 \
        gettext \
        gnupg2 \
        locales-all \
        nano \
        npm \
        openssh-client \
        telnet \
        vim \
        zlibc \
    && echo 'deb https://apt-archive.postgresql.org/pub/repos/apt buster-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends \
    && curl --silent -L --output /tmp/geoipupdate_${GEOIP_UPDATER_VERSION}_linux_amd64.deb https://github.com/maxmind/geoipupdate/releases/download/v${GEOIP_UPDATER_VERSION}/geoipupdate_${GEOIP_UPDATER_VERSION}_linux_amd64.deb \
    && dpkg -i /tmp/geoipupdate_${GEOIP_UPDATER_VERSION}_linux_amd64.deb \
    && apt-get autopurge -yqq \
    && sync

WORKDIR /opt/odoo
COPY bin/* /usr/local/bin/
COPY lib/doodbalib /usr/local/lib/python3.6/site-packages/doodbalib
COPY build.d common/build.d
COPY conf.d common/conf.d
COPY entrypoint.d common/entrypoint.d
RUN rm -f /opt/odoo/common/conf.d/60-geoip-ge17.conf \
    && mv /opt/odoo/common/conf.d/60-geoip-lt17.conf /opt/odoo/common/conf.d/60-geoip.conf \
    && rm -f /opt/odoo/common/conf.d/70-database-replica-ge18.conf \
    && git config --system pull.rebase false \
    && git config --system init.defaultBranch main
RUN mkdir -p auto/addons auto/geoip custom/src/private \
    && ln /usr/local/bin/direxec common/entrypoint \
    && ln /usr/local/bin/direxec common/build \
    && chmod -R a+rx common/entrypoint* common/build* /usr/local/bin \
    && chmod -R a+rX /usr/local/lib/python3.6/site-packages/doodbalib \
    && cp -a /etc/GeoIP.conf /etc/GeoIP.conf.orig \
    && mv /etc/GeoIP.conf /opt/odoo/auto/geoip/GeoIP.conf \
    && ln -s /opt/odoo/auto/geoip/GeoIP.conf /etc/GeoIP.conf \
    && sed -i 's/.*DatabaseDirectory .*$/DatabaseDirectory \/opt\/odoo\/auto\/geoip\//g' /opt/odoo/auto/geoip/GeoIP.conf \
    && sync

# Doodba-QA dependencies in a separate virtualenv
COPY qa /qa
RUN --mount=target=/root/.cache/pip,type=cache,id=pip-cache \
    python -m venv --system-site-packages /qa/venv \
    && . /qa/venv/bin/activate \
    && pip install \
        click \
        coverage \
        six \
    && deactivate \
    && mkdir -p /qa/artifacts \
    && git clone --depth 1 $MQT /qa/mqt

ARG ODOO_SOURCE=OCA/OCB

# Install Odoo hard & soft dependencies, and Doodba utilities
RUN --mount=target=/var/lib/apt/lists,type=cache,id=apt-lists-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/var/cache/apt,type=cache,id=apt-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
    --mount=target=/root/.cache/pip,type=cache,id=pip-cache \
    --mount=target=/tmp,type=tmpfs \
    build_deps=" \
        build-essential \
        libfreetype6-dev \
        libfribidi-dev \
        libghc-zlib-dev \
        libharfbuzz-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjp2-7-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt-dev \
        tcl-dev \
        tk-dev \
        zlib1g-dev \
    " \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends $build_deps \
    && pip install \
        -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        'websocket-client~=0.56' \
        astor \
        "git-aggregator<3.0.0" \
        # Install fix from https://github.com/acsone/click-odoo-contrib/pull/93
        git+https://github.com/Tecnativa/click-odoo-contrib.git@fix-active-modules-hashing \
        "pg_activity<2.0.0" \
        phonenumbers \
        plumbum \
        ptvsd \
        debugpy \
        pydevd-odoo \
        pudb \
        python-magic \
        watchdog \
        wdb \
        geoip2 \
        inotify \
    && (python3 -m compileall -q /usr/local/lib/python3.6/ || true) \
    && apt-get purge -yqq $build_deps \
    && apt-get autopurge -yqq

# Metadata
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.label-schema.schema-version="$VERSION" \
      org.label-schema.vendor=Tecnativa \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/Tecnativa/doodba"

# Onbuild version, with all the magic
FROM base AS onbuild

# Enable setting custom uids for odoo user during build of scaffolds
ONBUILD ARG UID=1000
ONBUILD ARG GID=1000

# Enable Odoo user and filestore
ONBUILD RUN groupadd -g $GID odoo -o \
    && useradd -l -md /home/odoo -s /bin/false -u $UID -g $GID odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo /qa/artifacts \
    && chmod a=rwX /qa/artifacts \
    && sync

# Subimage triggers
ONBUILD ENTRYPOINT ["/opt/odoo/common/entrypoint"]
ONBUILD CMD ["/usr/local/bin/odoo"]
ONBUILD ARG TARGETARCH
ONBUILD ARG AGGREGATE=true
ONBUILD ARG DEFAULT_REPO_PATTERN="https://github.com/OCA/{}.git"
ONBUILD ARG DEFAULT_REPO_PATTERN_ODOO="https://github.com/OCA/OCB.git"
ONBUILD ARG DEPTH_DEFAULT=1
ONBUILD ARG DEPTH_MERGE=100
ONBUILD ARG CLEAN=true
ONBUILD ARG COMPILE=true
ONBUILD ARG FONT_MONO="Liberation Mono"
ONBUILD ARG FONT_SANS="Liberation Sans"
ONBUILD ARG FONT_SERIF="Liberation Serif"
ONBUILD ARG PIP_INSTALL_ODOO=true
ONBUILD ARG ADMIN_PASSWORD=admin
ONBUILD ARG SMTP_SERVER=smtp
ONBUILD ARG SMTP_PORT=25
ONBUILD ARG SMTP_USER=false
ONBUILD ARG SMTP_PASSWORD=false
ONBUILD ARG SMTP_SSL=false
ONBUILD ARG EMAIL_FROM=""
ONBUILD ARG PROXY_MODE=false
ONBUILD ARG WITHOUT_DEMO=all
ONBUILD ARG PGUSER=odoo
ONBUILD ARG PGPASSWORD=odoopassword
ONBUILD ARG PGHOST=db
ONBUILD ARG PGPORT=5432
ONBUILD ARG PGDATABASE=prod
ONBUILD ARG HTTP_INTERFACE="0.0.0.0"

# Config variables
ONBUILD ENV ADMIN_PASSWORD="$ADMIN_PASSWORD" \
            DEFAULT_REPO_PATTERN="$DEFAULT_REPO_PATTERN" \
            DEFAULT_REPO_PATTERN_ODOO="$DEFAULT_REPO_PATTERN_ODOO" \
            UNACCENT="$UNACCENT" \
            PGUSER="$PGUSER" \
            PGPASSWORD="$PGPASSWORD" \
            PGHOST="$PGHOST" \
            PGPORT=$PGPORT \
            PGDATABASE="$PGDATABASE" \
            PROXY_MODE="$PROXY_MODE" \
            SMTP_SERVER="$SMTP_SERVER" \
            SMTP_PORT=$SMTP_PORT \
            SMTP_USER="$SMTP_USER" \
            SMTP_PASSWORD="$SMTP_PASSWORD" \
            SMTP_SSL="$SMTP_SSL" \
            EMAIL_FROM="$EMAIL_FROM" \
            WITHOUT_DEMO="$WITHOUT_DEMO" \
            HTTP_INTERFACE="$HTTP_INTERFACE"
ONBUILD ARG LOCAL_CUSTOM_DIR=./custom
ONBUILD COPY --chown=root:odoo $LOCAL_CUSTOM_DIR /opt/odoo/custom

# https://docs.python.org/3/library/logging.html#levels
ONBUILD ARG LOG_LEVEL=INFO
ONBUILD RUN mkdir -p /opt/odoo/custom/ssh \
            && ln -s /opt/odoo/custom/ssh ~root/.ssh \
            && chmod -R u=rwX,go= /opt/odoo/custom/ssh \
            && sync
ONBUILD ARG DB_VERSION=latest
ONBUILD RUN --mount=target=/var/lib/apt/lists,type=cache,id=apt-lists-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
            --mount=target=/var/cache/apt,type=cache,id=apt-${TARGETARCH}-${ODOO_VERSION},sharing=locked \
            --mount=target=/root/.cache/pip,type=cache,id=pip-cache \
            --mount=target=/tmp,type=tmpfs \
            /opt/odoo/common/build && sync
ONBUILD VOLUME ["/var/lib/odoo"]
ONBUILD USER odoo
