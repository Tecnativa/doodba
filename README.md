# [Dockerized Odoo Base Image](https://hub.docker.com/r/tecnativa/odoo-base)

[![](https://images.microbadger.com/badges/version/tecnativa/odoo-base:latest.svg)](https://microbadger.com/images/tecnativa/odoo-base:latest "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/tecnativa/odoo-base:latest.svg)](https://microbadger.com/images/tecnativa/odoo-base:latest "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/tecnativa/odoo-base:latest.svg)](https://microbadger.com/images/tecnativa/odoo-base:latest "Get your own commit badge on microbadger.com")
[![](https://images.microbadger.com/badges/license/tecnativa/odoo-base.svg)](https://microbadger.com/images/tecnativa/odoo-base "Get your own license badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/tecnativa/odoo-base:8.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:8.0 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/tecnativa/odoo-base:8.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:8.0 "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/tecnativa/odoo-base:8.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:8.0 "Get your own commit badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/tecnativa/odoo-base:9.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:9.0 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/tecnativa/odoo-base:9.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:9.0 "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/tecnativa/odoo-base:9.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:9.0 "Get your own commit badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/tecnativa/odoo-base:10.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:10.0 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/tecnativa/odoo-base:10.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:10.0 "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/tecnativa/odoo-base:10.0.svg)](https://microbadger.com/images/tecnativa/odoo-base:10.0 "Get your own commit badge on microbadger.com")

[![](https://api.travis-ci.org/Tecnativa/docker-odoo-base.svg)](https://travis-ci.org/Tecnativa/docker-odoo-base)

Highly opinionated image ready to put [Odoo](https://www.odoo.com) inside it,
but **without Odoo**.

## What?

Yes, the purpose of this is to serve as a base for you to build your own Odoo
project, because most of them end up requiring a big amount of custom patches,
merges, repositories, etc. With this image, you have a collection of good
practices and tools to enable your team to have a standard Odoo project
structure.

BTW, we use [Debian][]. I hope you like that.

  [Debian]: https://debian.org/

## Why?

Because developing Odoo is hard. You need lots of customizations, dependencies,
and if you want to move from one version to another, it's a pain.

Also because nobody wants Odoo as it comes from upstream, you most likely will
need to add custom patches and addons, at least, so we need a way to put all
together and make it work anywhere quickly.

## How?

You can start working with this straight away with our [scaffolding][].

## Image usage

Basically, every directory you have to worry about is found inside `/opt/odoo`.
This is its structure:

    custom/
        entrypoint.d/
        build.d/
        conf.d/
        ssh/
            config
            known_hosts
            id_rsa
            id_rsa.pub
        dependencies/
            apt_build.txt
            apt.txt
            gem.txt
            npm.txt
            pip.txt
        src/
            private/
            odoo/
            addons.yaml
            repos.yaml
    common/
        entrypoint.sh
        build.sh
        entrypoint.d/
        build.d/
        conf.d/
    auto
        addons/
        odoo.conf

Let's go one by one.

### `/opt/odoo/custom`: The important one

Here you will put everything related to your project.

#### `/opt/odoo/custom/entrypoint.d`

Any executables found here will be run when you launch your container, before
running the command you ask.

#### `/opt/odoo/custom/build.d`

Executables here will be aggregated with those in `/opt/odoo/common/build.d`.

The resulting set of executables will then be sorted alphabetically (ascending)
and then subsequently run.

#### `/opt/odoo/custom/conf.d`

Files here will be environment-variable-expanded and concatenated in
`/opt/odoo/auto/odoo.conf` at build time.

#### `/opt/odoo/custom/ssh`

It must follow the same structure as a standard `~/.ssh` directory, including
`config` and `known_hosts` files. In fact, it is completely equivalent to
`~root/.ssh`.

The `config` file can contain `IdentityFile` keys to represent the private
key that should be used for that host. Unless specified otherwise, this
defaults to `identity[.pub]`, `id_rsa[.pub]` or `id_dsa[.pub]` files found in
this same directory.

This is very useful **to use deployment keys** that grant git access to your
private repositories.

Example - a private key file in the `ssh` folder named `my_private_key` for
the host `repo.example.com` would have a `config` entry similar to the below:

```
Host repo.example.com
  IdentityFile ~/.ssh/my_private_key
```

Or you could just drop the key in `id_rsa` and `id_rsa.pub` files and it should
work by default without the need of adding a `config` file.

Host key checking is enabled by default, which means that you also need to
provide a `known_hosts` file for any repos that you wish to access via SSH.

In order to disable host key checks for a repo, your config would look something
like this:

```
Host repo.example.com
  StrictHostKeyChecking no
```

For additional information regarding this directory, take a look at this
[Digital Ocean Article][ssh-conf].

#### `/opt/odoo/custom/src`

Here you will put the actual source code for your project.

When putting code here, you can either:

- Use [`repos.yaml`][], that will fill anything at build time.
- Directly copy all there.

Recommendation: use [`repos.yaml`][] for everything except for [`private`][],
and ignore in your `.gitignore` and `.dockerignore` files every folder here
except [`private`][], with rules like these:

    odoo/custom/src/*
    !odoo/custom/src/private
    !odoo/custom/src/*.*

##### `/opt/odoo/custom/src/odoo`

**REQUIRED.** The source code for your odoo project.

You can choose your Odoo version, and even merge PRs from many of them using
[`repos.yaml`][]. Some versions you might consider:

- [Original Odoo][], by [Odoo S.A.][].

- [OCB][] (Odoo Community Backports), by [OCA][].
  The original + some features - some stability strictness.

- [OpenUpgrade][], by [OCA][].
  The original, frozen at new version launch time + migration scripts.

##### `/opt/odoo/custom/src/private`

**REQUIRED.** Folder with private addons for the project.

##### `/opt/odoo/custom/src/repos.yaml`

A [git-aggregator](#git-aggregator) configuration file.

##### `/opt/odoo/custom/src/addons.yaml`

One entry per repo and addon you want to activate in your project. Like this:

```yaml
website:
    - website_cookie_notice
    - website_legal_page
web:
    - web_responsive
```

Advanced features:

- You can bundle [several YAML documents][] if you want to logically group your
  addons and some repos are repeated among groups, by separating each document
  with `---`.

- Addons under `private` and `odoo/addons` are linked automatically unless you
  specify them.

- You can use `ONLY` to supply a dictionary of environment variables and a
  list of possible values to enable that document in the matching environments.

- If an addon is found in several places at the same time, it will get linked
  according to this priority table:

  1. Addons in [`private`][].
  2. Addons in other repositories (in case one is matched in several, it will
     be random, BEWARE!). Better have no duplicated names if possible.
  3. Core Odoo addons from [`odoo/addons`][`odoo`].

- If an addon is specified but not available at runtime, it will fail silently.

- You can use any wildcards supported by [Python's glob module][glob].

This example shows these advanced features:

```yaml
# Spanish Localization
l10n-spain:
  - l10n_es # Overrides built-in l10n_es under odoo/addons
server-tools:
  - "*date*" # All modules that contain "date" in their name
  - module_auto_update # Makes `autoupdate` script actually autoupdate addons
web:
  - "*" # All web addons
---
# Different YAML document to separate SEO Tools
website:
  - website_blog_excertp_img
server-tools: # Here we repeat server-tools, but no problem because it's a
              # different document
  - html_image_url_extractor
  - html_text
---
# Enable demo ribbon only for devel and test environments
ONLY:
  PGDATABASE: # This environment variable must exist and be in the list
    - devel
    - test
server-tools:
  - web_environment_ribbon
---
# Enable special authentication methods only in production environment
ONLY:
  PGDATABASE:
    - prod
server-tools:
  - auth_*
```

##### `/opt/odoo/custom/dependencies/*.txt`

Files to indicate dependencies of your subimage, one for each of the supported
package managers:

- `apt_build.txt`: build-time dependencies, installed before any others and
  removed after all the others too. Usually these would include Debian packages
  such as `build-essential` or `python-dev`.
- `apt.txt`: run-time dependencies installed by apt.
- `gem.txt`: run-time dependencies installed by gem.
- `npm.txt`: run-time dependencies installed by npm.
- `pip.txt`: a normal [pip `requirements.txt`][] file, for run-time
  dependencies too. It will get executed with `--update` flag, just in case
  you want to overwrite any of the pre-bundled dependencies.

### `/opt/odoo/common`: The useful one

This folder is full of magic. I'll document it some day. For now, just look at
the code.

Only some notes:

- Will compile your code with [`PYTHONOPTIMIZE=2`][] by default.

- Will remove all code not used from the image by default (not listed in
  `/opt/odoo/custom/src/addons.yaml`), to keep it thin.

### `/opt/odoo/auto`: The automatic one

This directory will have things that are automatically generated at build time.

#### `/opt/odoo/auto/addons`

It will be full of symlinks to the addons you selected in [`addons.yaml`][].

#### `/opt/odoo/auto/odoo.conf`

It will have the result of merging all configurations under
`/opt/odoo/{common,custom}/conf.d/`, in that order.

## The `Dockerfile`

I will document all build arguments and environment variables some day, but for
now keep this in mind:

- This is just a base image, full of tools. **You need to build your project
  subimage** from this one, even if your project's `Dockerfile` only contains
  these 2 lines:

      FROM tecnativa/odoo-base
      MAINTAINER Me <me@example.com>

- The above sentence becomes true because we have a lot of `ONBUILD` sentences
  here, so at least **your project must have a `./custom` folder** along with
  its `Dockerfile` for it to work.

- All should be magic if you adhere to our opinions here. Just put the code
  where it should go, and relax.

## Bundled tools

### `addons`

A handy CLI tool to automate addon management based on the current environment.
It allows you to install, update, test and/or list private, extra and/or core
addons available to current container, based on current [`addons.yaml`][]
configuration.

Call `addons --help` for usage instructions.

### [`nano`][]

The CLI text editor we all know, just in case you need to inspect some bug in
hot deployments.

### `log`

Just a little shell script that you can use to add logs to your build or
entrypoint scripts:

    log INFO I'm informing

### `pot`

Little shell shortcut for exporting a translation template from any addon(s).
Usage:

    pot my_addon,my_other_addon

### `python-odoo-shell`

Little shortcut to make your `odoo shell` scripts executable.

For example, create this file in your scaffolding-based project:
`odoo/custom/shell-scripts/whoami.py`. Fill it with:

```python
#!/usr/local/bin/python-odoo-shell
from __future__ import print_function
print(env.user.name)
print(env.context)
```

Now run it:

```bash
$ chmod a+x odoo/custom/shell-scripts/whoami.py  # Make it executable
$ docker-compose build --pull  # Rebuild the image, unless in devel
$ docker-compose run --rm odoo custom/shell-scripts/whoami.py
```

### `unittest`

Another little shell script, useful for debugging. Just run it like this and
Odoo will execute unit tests in its default database:

    unittest my_addon,my_other_addon

Note that the addon must be installed for it to work. Otherwise, you should run
it as:

    unittest my_addon,my_other_addon -i my_addon,my_other_addon

### [`psql`](https://www.postgresql.org/docs/9.5/static/app-psql.html)

Environment variables are there so that if you need to connect with the
database, you just need to execute:

    docker exec -it your_container psql

### [`wdb`](https://github.com/Kozea/wdb/)

In our opinion, this is the greatest Python debugger available, mostly for
Docker-based development, so here you have it preinstalled.

I told you, this image is opinionated. :wink:

To use it, write this in any Python script:

```python
import wdb
wdb.set_trace()
```

**DO NOT USE IT IN PRODUCTION ENVIRONMENTS.** (I had to say it).

### [`ptvsd`](https://github.com/DonJayamanne/pythonVSCode)

[VSCode][] debugger. If you use this editor with its python module, you will
find it useful.

To debug, add this Python code somewhere:

```python
import ptvsd
ptvsd.enable_attach("my_secret", address=("0.0.0.0", 6899))
print("ptvsd waiting...")
ptvsd.wait_for_attach()
```

Of course, you need to have properly configured your [VSCode][]. To do so, make
sure in your project there is a `.vscode/launch.json` file with these minimal
contents:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Attach to debug in devel.yaml",
            "type": "python",
            "request": "attach",
            "localRoot": "${workspaceRoot}/odoo",
            "remoteRoot": "/opt/odoo",
            "port": 6899,
            "secret": "my_secret",
            "host": "localhost"
        }
    ]
}
```

Then, execute that configuration as usual.

### [`pudb`](https://github.com/inducer/pudb)

This is another great debugger that includes remote debugging via telnet, which
can be useful for some cases, or for people that prefer it over wdb.

To use it, inject this in any Python script:

```python
import pudb.remote
pudb.remote.set_trace(term_size=(80, 24))
```

Then open a telnet connection to it (running in `0.0.0.0:6899` by default).

It is safe to use in production environments **if you know what you are doing
and do not expose the debugging port to attackers**. Assuming you use the
[scaffolding][] production environment, you can achieve that with:

    docker-compose -f prod.yaml exec odoo telnet localhost 6899

### [`git-aggregator`](https://pypi.python.org/pypi/git-aggregator)

We found this one to be the most useful tool for downlading code, merging it
and placing it somewhere.

### `autoaggregate`

This little script wraps `git-aggregator` to make it work fine and
automatically with this image. Used in the [scaffolding][]'s `setup-devel.yaml`
step.

#### Example [`repos.yaml`][] file

This example merges [several sources][`odoo`]:

    ./odoo:
        defaults:
            # Shallow repositores are faster & thinner. You better use
            # $DEPTH_DEFAULT here when you need no merges.
            depth: $DEPTH_MERGE
        remotes:
            ocb: https://github.com/OCA/OCB.git
            odoo: https://github.com/odoo/odoo.git
        target:
            ocb $ODOO_VERSION
        merges:
            - ocb $ODOO_VERSION
            - odoo refs/pull/13635/head

### [`odoo`](https://www.odoo.com/documentation/10.0/reference/cmdline.html)

We set an `$OPENERP_SERVER` environment variable pointing to [the autogenerated
configuration file](#optodooautoodooconf) so you don't have to worry about
it. Just execute `odoo` and it will work fine.

Note that version 9.0 has an `odoo` binary to provide forward compatibility
(but it has the `odoo.py` one too).

## Scaffolding

Get up and running quickly with the provided
[scaffolding](https://github.com/Tecnativa/docker-odoo-base/tree/scaffolding).

### Skip the boring parts

I will assume you know how to use Git, Docker and Docker Compose.

    git clone -b scaffolding https://github.com/Tecnativa/docker-odoo-base.git myproject
    cd myproject
    ln -s devel.yaml docker-compose.yml
    chown -R $USER:1000 odoo/auto
    chmod -R ug+rwX odoo/auto
    export UID="$(id -u $USER)" GID="$(id -g $USER)" UMASK="$(umask)"
    docker-compose build --pull
    docker-compose -f setup-devel.yaml run --rm odoo
    docker-compose up

And if you don't want to have a chance to do a `git merge` and get possible
future scaffolding updates merged in your project's `git log`:

    rm -Rf .git
    git init

### Tell me the boring parts

The scaffolding provides you a boilerplate-ready project to start developing
Odoo in no time.

#### Environments

This scaffolding comes with some environment configurations, ready for you to
extend them. Each of them is a [Docker Compose
file](https://docs.docker.com/compose/compose-file/) almost ready to work out
of the box (or almost), but that will assume that you understand it and will
modify it.

After you clone the scaffolding, **search for `XXX` comments**, they will help
you on making it work.

##### Development

Set it up with:

    export UID="$(id -u $USER)" GID="$(id -g $USER)" UMASK="$(umask)"
    docker-compose -f setup-devel.yaml run --rm odoo

Once finished, you can start using Odoo with:

    docker-compose -f devel.yaml up --build

This allows you to track only what Git needs to track and provides faster
Docker builds.

You might consider adding this line to your `~/.bashrc`:

    export UID="$(id -u $USER)" GID="$(id -g $USER)" UMASK="$(umask)"

##### Production

This environment is just a template. **It is not production-ready**. You must
change many things inside it, it's just a guideline.

It includes pluggable `smtp` and `backup` services.

Once you fixed everything needed, run it with:

    docker-compose -f prod.yaml up --build --remove-orphans

Remember that you will want to backup the filestore in `/var/lib/odoo` volume.

###### Global inverse proxy

For production and test templates to work fine, you need to have a working
[Traefik][] inverse proxy in each node.

To have it, use this `inverseproxy.yaml` file:

```yaml
version: "2.1"

services:
    proxy:
        image: traefik:1.3-alpine
        networks:
            shared:
            private:
        volumes:
            - acme:/etc/traefik/acme:rw,Z
        ports:
            - "80:80"
            - "443:443"
        depends_on:
            - dockersocket
        restart: unless-stopped
        privileged: true
        tty: true
        command:
            - --ACME.ACMELogging
            - --ACME.Email=you@example.com
            - --ACME.EntryPoint=https
            - --ACME.OnHostRule
            - --ACME.Storage=/etc/traefik/acme/acme.json
            - --DefaultEntryPoints=http,https
            - --EntryPoints=Name:http Address::80 Redirect.EntryPoint:https
            - --EntryPoints=Name:https Address::443 TLS
            - --LogLevel=INFO
            - --Docker
            - --Docker.EndPoint=http://dockersocket:2375
            - --Docker.ExposedByDefault=false
            - --Docker.Watch

    dockersocket:
        image: tecnativa/docker-socket-proxy
        privileged: true
        networks:
            private:
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
        environment:
            CONTAINERS: 1
            NETWORKS: 1
            SERVICES: 1
            SWARM: 1
            TASKS: 1
        restart: unless-stopped

networks:
    shared:
        driver_opts:
            encrypted: 1

    private:
        driver_opts:
            encrypted: 1

volumes:
    acme:
```

Then boot it up with:

    docker-compose -p inverseproxy -f inverseproxy.yaml up -d

This will intercept all requests coming from port 80 (`http`) and redirect them
to port 443 (`https`), it will download and install required SSL certificates
from [Let's Encrypt][] whenever you boot a new production instance, add the
required proxy headers to the request, and then redirect all traffic to/from
odoo automatically.

It includes [a security-enhaced proxy][docker-socket-proxy] to reduce attack
surface when listening to the Docker socket.

This allows you to:

* Have multiple domains for each Odoo instance.
* Have multiple Odoo instances in each node.
* Add an SSL layer automatically and for free.

##### Testing

A good rule of thumb is test in testing before uploading to production, so this
environment tries to imitate the production one in everything, but *removing
possible pollution points*:

- It has no `smtp` service.

- It has no `backup` service.

Test it in your machine with:

    docker-compose -f test.yaml up --build

#### Other usage scenarios

In examples below I will skip the `-f <environment>.yaml` part and assume you
know which environment you want to use.

Also, we recommend to use `run` subcommand to create a new container with same
settings and volumes. Sometimes you may prefer to use `exec` instead, to
execute an arbitrary command in a running container.

##### Inspect the database

    docker-compose run --rm odoo psql

##### Restart Odoo

You will need to restart it whenever any Python code changes, so to do that:

    docker-compose restart -t0 odoo

In production:

    docker-compose restart odoo https

##### Run unit tests for some addon

    docker-compose run --rm odoo odoo --stop-after-init --init addon1,addon2
    docker-compose run --rm odoo unittest addon1,addon2

##### Reading the logs

For all services in the environment:

    docker-compose logs -f --tail 10

Only Odoo's:

    docker-compose logs -f --tail 10 odoo

##### Install some addon without stopping current running process

    docker-compose run --rm odoo odoo -i addon1,addon2 --stop-after-init

##### Update some addon without stopping current running process

    docker-compose run --rm odoo odoo -u addon1,addon2 --stop-after-init

##### Update changed addons only

Add `module_auto_update` from https://github.com/OCA/server-tools to your
installation following the standard methods of `repos.yaml` + `addons.yaml`.

Now we will install the addon:

    docker-compose up -d
    docker-compose run --rm odoo --stop-after-init -u base
    docker-compose run --rm odoo --stop-after-init -i module_auto_update
    docker-compose restart odoo

It will automatically update addons that got updated every night.
To force that automatic update now in a separate container:

    docker-compose up -d
    docker-compose run --rm odoo autoupdate
    docker-compose restart odoo

##### Export some addon's translations to stdout

    docker-compose run --rm odoo pot addon1[,addon2]

Now copy the relevant parts to your `addon1.pot` file.

##### Open an odoo shell

    docker-compose run --rm odoo odoo shell

##### Open another UI instance linked to same filestore and database

    docker-compose run --rm -p 127.0.0.1:$SomeFreePort:8069 odoo

Then open `http://localhost:$SomeFreePort`.

## FAQ

### Will there be not retrocompatible changes on the image?

This image is production-ready, but it is constantly evolving too, so some new
features can break some old ones, or conflict with them, and some old features
might get deprecated and removed at some point.

The best you can do is to [subscribe to the compatibility breakage
announcements issue][retrobreak].

### I need to force addition or removal of `www.` prefix in production

[We hope that some day Traefik supports that feature][www-force], but in the
mean time, you must add an additional proxy to do that.

To **remove** the `www.` prefix, add this service to `prod.yaml`:

```yaml
www_remove:
    image: tecnativa/odoo-proxy
    environment:
        FORCEHOST: $DOMAIN_PROD
    networks:
        default:
        inverseproxy_shared:
    labels:
        traefik.docker.network: "inverseproxy_shared"
        traefik.enable: "true"
        traefik.frontend.passHostHeader: "true"
        traefik.port: "80"
        traefik.frontend.rule: "Host:www.${DOMAIN_PROD}"
```

To **add** the `www.` prefix, it is almost the same; use your imagination
:wink:.

### How to allow access from several host names?

In `.env`, set `DOMAIN_PROD` to `host1.com,host2.com,www.host1.com`, etc.

### When I try to `export UID="$(id -u $USER)"` bash says it is readonly

I guess you were trying to follow the instructions to run the
`setup-devel.yaml` environment and you use Bash as your shell.

In such case, just do `export UID`, which just exports the
already-existing-but-hidden-and-readonly bash `$UID` variable.

Or you could switch to a better shell, such as [Fish][]. If you choose this
option, you can export them for current terminal session with:

    set -x UID (id -u $USER)
    set -x GID (id -g $USER)
    set -x UMASK (umask)

You can make those variables universal (available in all terminals you open
from now on) by using `set -Ux` instead of `set -x`.

### When I boot `devel.yaml` for the first time, Odoo crashes

Most likely you are using versions `8.0` or `9.0` of the image. If so:

1. Edit `devel.yaml`.
2. Search for the line that starts with `command:` in the `odoo` service.
3. Change it for a command that actually works with your version:
   - `odoo --workers 0` for Odoo 8.0.
   - `odoo --workers 0 --dev` for Odoo 9.0.

### This project is too opinionated, but can I question any of those opinions?

Of course. There's no guarantee that we will like it, but please do it. :wink:

### What's this `hooks` folder here?

It runs triggers when doing the automatic build in the Docker Hub.
[Check this](https://hub.docker.com/r/thibaultdelor/testautobuildhooks/).

### Can I have my own [scaffolding][]?

You probably **should**, and rebase on our updates. However, if you are
planning on a general update to it that you find interesting for the
general-purpose one, please send us a pull request.

### Can I skip the `-f <environment>.yaml` part for `docker-compose` commands?

Let's suppose you want to use `test.yaml` environment by default, no matter
where you clone the project:

    ln -s test.yaml docker-compose.yaml
    git add docker-compose.yaml
    git commit

Let's suppose you only want to use `devel.yaml` in your local development
machine by default:

    ln -s devel.yaml docker-compose.yml

Notice the difference in the prefix (`.yaml` vs. `.yml`). Docker Compose will
use the `.yml` one if both are found, so that's the one we considered you
should use in your local clones, and that's the one that will be git-ignored by
default by the scaffolding `.gitignore` file.

Another option is that you use the [`COMPOSE_FILE` environment variable][].
Returning to the example where you are in your local development machine, you
might want to add this to your `~/.bashrc` or equivalent:

    export COMPOSE_FILE=docker-compose.yml:docker-compose.yaml:devel.yaml

As a design choice, the scaffolding defaults to being explicit.

### How can I pin an image version?

Version-pinning is a good idea to keep your code from differing among image
updates. It's the best way to ensure no updates got in between the last time
you checked the image and the time you deploy it to production.

You can do it through **its sha256 code**.

Get any image's code through inspect, running from a computer where the correct
image version is downloaded:

    docker image inspect --format='{{.RepoDigests}}' tecnativa/odoo-base:10.0

Alternatively, you can browse [this image's builds][builds], click on the one
you know it works fine for you, and search for the `digest` word using your
browser's *search in page* system (Ctrl+F usually).

You will find lines similar to:

    [...]
    10.0: digest: sha256:fba69478f9b0616561aa3aba4d18e4bcc2f728c9568057946c98d5d3817699e1 size: 4508
    [...]
    8.0: digest: sha256:27a3dd3a32ce6c4c259b4a184d8db0c6d94415696bec6c2668caafe755c6445e size: 4508
    [...]
    9.0: digest: sha256:33a540eca6441b950d633d3edc77d2cc46586717410f03d51c054ce348b2e977 size: 4508
    [...]

Once you find them, you can use that pinned version in your builds, using a
Dockerfile similar to this one:

```Dockerfile
# Hash-pinned version of tecnativa/odoo-base:10.0
FROM tecnativa/odoo-base@sha256:fba69478f9b0616561aa3aba4d18e4bcc2f728c9568057946c98d5d3817699e1
```

### How can I help?

Just [head to our project](https://github.com/Tecnativa/docker-odoo-base) and
open an issue or pull request.

If you plan to open a pull request, remember that you will usually have to open
two of them:

1. Targeting the `master` branch, from which the main images are built.
   This pull request must include tests.
2. Targeting the `scaffolding` branch, which serves as the base for projects
   using this base image. This one is not always required.

If you need to add a feature or fix for `scaffolding`, before merging that PR,
we need tests that ensure that backwards compatibility with previous
scaffolding versions is preserved.

## Related Projects

- [Ansible role for automated deployment / update from Le Filament](https://github.com/remi-filament/ansible_role_odoo_docker)


[`/opt/odoo/auto/addons`]: #optodooautoaddons
[`addons.yaml`]: #optodoocustomsrcaddonstxt
[`COMPOSE_FILE` environment variable]: https://docs.docker.com/compose/reference/envvars/#/composefile
[`nano`]: https://www.nano-editor.org/
[`odoo.conf`]: #optodooautoodooconf
[`odoo`]: #optodoocustomsrcodoo
[`private`]: #optodoocustomsrcprivate
[`PYTHONOPTIMIZE=2`]: https://docs.python.org/2/using/cmdline.html#envvar-PYTHONOPTIMIZE
[`repos.yaml`]: #optodoocustomsrcreposyaml
[builds]: https://hub.docker.com/r/tecnativa/odoo-base/builds/
[docker-socket-proxy]: https://hub.docker.com/r/tecnativa/docker-socket-proxy/
[Fish]: http://fishshell.com/
[glob]: https://docs.python.org/3/library/glob.html
[Let's Encrypt]: https://letsencrypt.org/
[OCA]: https://odoo-community.org/
[OCB]: https://github.com/OCA/OCB
[Odoo S.A.]: https://www.odoo.com
[OpenUpgrade]: https://github.com/OCA/OpenUpgrade/
[Original Odoo]: https://github.com/odoo/odoo
[pip `requirements.txt`]: https://pip.readthedocs.io/en/latest/user_guide/#requirements-files
[retrobreak]: https://github.com/Tecnativa/docker-odoo-base/issues/67
[scaffolding]: #scaffolding
[several YAML documents]: http://www.yaml.org/spec/1.2/spec.html#id2760395
[ssh-conf]: https://www.digitalocean.com/community/tutorials/how-to-configure-custom-connection-options-for-your-ssh-client
[Traefik]: https://traefik.io/
[VSCode]: https://code.visualstudio.com/
[www-force]: https://github.com/containous/traefik/issues/1380
