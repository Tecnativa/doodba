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
        ssh.d/
        src/
            private/
            odoo/
            addons.yaml
            repos.yaml
            requirements.txt
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

Executables here will run just before those in `/opt/odoo/common/build.d`.

#### `/opt/odoo/custom/conf.d`

Files here will be environment-variable-expanded and concatenated in
`/opt/odoo/auto/odoo.conf` at build time.

#### `/opt/odoo/custom/ssh.d`

Files here will be used to create the `root` and `odoo` users' SSH directories.

It should follow the same structure as a standard `~/.ssh` directory, including
`config` and `known_hosts` files.

The `config` file should contain `IdentityFile` keys to represent the private
key that should be used for that host. The key will be located in  `~/.ssh/`.

Example - a private key file in the `ssh.d` folder named `my_private_key` for
the host `repo.example.com` would have a `config` entry similar to the below:

```
Host repo.example.com
  IdentityFile ~/.ssh/my_private_key
```

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

You can bundle [several YAML documents][] if you want to logically group your
addons and some repos are repeated among groups, by separating each document
with `---`:

```yaml
# Spanish Localization
l10n-spain:
    - l10n_es
server-tools:
    - date_range
---
# SEO tools
website:
    - website_blog_excertp_img
server-tools: # Here we repeat server-tools, but no problem because it's a
              # different document
    - html_image_url_extractor
    - html_text
```

You can add all modules in a repo by using a `*`:

```yaml
website:
    - "*"
```

Important notes:

- Do not add repos for the required [`odoo`][] and [`private`][] directories;
  those are automatic.

- Only addons here are symlinked in [`/opt/odoo/auto/addons`][]. Addons from
  the required directories above are added directly in the [`odoo.conf`][]
  file.

- This means that if you have an addon with the same name in any of [`odoo`][],
  [`private`][] or [`/opt/odoo/auto/addons`][] directories, this will be the
  importance order in which they will be loaded (from most to least important):

  1. Addons in [`private`][].
  2. Custom addons listed in [`addons.yaml`][].
  3. Core Odoo addons from [`./odoo/addons`][`odoo`].

  Although it is better to simply have no name conflicts if possible.

- Any other addon not listed here will not be usable in Odoo (and will be
  removed by default, to keep the resulting image thin).

- If you list 2 addons with the same name, you'll get a build error.

- If you use the wildcard (`*`), it must be encapsulated in quotes.

##### `/opt/odoo/custom/src/requirements.txt`

A normal [pip `requirements.txt`][] file, to install dependencies for your
addons when building the subimage.

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

##### Export some addon's translations to stdout

    docker-compose run --rm odoo pot addon1[,addon2]

Now copy the relevant parts to your `addon1.pot` file.

##### Open an odoo shell

    docker-compose run --rm odoo odoo shell

##### Open another UI instance linked to same filestore and database

    docker-compose run --rm -p 127.0.0.1:$SomeFreePort:8069 odoo

Then open `http://localhost:$SomeFreePort`.

## FAQ

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

### When I boot `devel.yaml` for the first time, Odoo crashes

Most likely you are using versions `8.0` or `9.0` of the image. If so:

1. Edit `devel.yaml`.
2. Search for the line that starts with `command:` in the `odoo` service.
3. Change it for a command that actually works with your version:
   - `odoo --workers 0` for Odoo 8.0.
   - `odoo --workers 0 --dev` for Odoo 9.0.

### Why my `99-whatever.sh` script in `/opt/odoo/*/*.d/` does not execute?

Files must be executable and have no `.` in their name.

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

### How can I help?

Just [head to our project](https://github.com/Tecnativa/docker-odoo-base) and
open an issue or pull request.

[`/opt/odoo/auto/addons`]: #optodooautoaddons
[`addons.yaml`]: #optodoocustomsrcaddonstxt
[`COMPOSE_FILE` environment variable]: https://docs.docker.com/compose/reference/envvars/#/composefile
[`nano`]: https://www.nano-editor.org/
[`odoo.conf`]: #optodooautoodooconf
[`odoo`]: #optodoocustomsrcodoo
[`private`]: #optodoocustomsrcprivate
[`PYTHONOPTIMIZE=2`]: https://docs.python.org/2/using/cmdline.html#envvar-PYTHONOPTIMIZE
[`repos.yaml`]: #optodoocustomsrcreposyaml
[docker-socket-proxy]: https://hub.docker.com/r/tecnativa/docker-socket-proxy/
[Let's Encrypt]: https://letsencrypt.org/
[OCA]: https://odoo-community.org/
[OCB]: https://github.com/OCA/OCB
[Odoo S.A.]: https://www.odoo.com
[OpenUpgrade]: https://github.com/OCA/OpenUpgrade/
[Original Odoo]: https://github.com/odoo/odoo
[pip `requirements.txt`]: https://pip.readthedocs.io/en/latest/user_guide/#requirements-files
[scaffolding]: #scaffolding
[several YAML documents]: http://www.yaml.org/spec/1.2/spec.html#id2760395
[Traefik]: https://traefik.io/
[VSCode]: https://code.visualstudio.com/
[www-force]: https://github.com/containous/traefik/issues/1380
