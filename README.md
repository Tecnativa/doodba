# [Dockerized Odoo Base Image](https://hub.docker.com/r/tecnativa/odoo-base)

Highly opinionated image ready to put [Odoo](https://www.odoo.com) inside it,
but **without Odoo**.

## What?

Yes, the purpose of this is to serve as a base for you to build your own Odoo
project, because most of them end up requiring a big amount of custom patches,
merges, repositories, etc. With this image, you have a collection of good
practices and tools to enable your team to have a standard Odoo project
structure.

BTW, we use [Alpine](https://alpinelinux.org/). I hope you like that.

## Image usage

Basically, every directory you have to worry about is found inside `/opt/odoo`.
This is its structure:

    custom/
        entrypoint.d/
        build.d/
        conf.d/
        src/
            private/
            odoo/
            addons.txt
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

- `./entrypoint.d`: Any executables found here will be run when you launch your
  container, before running the command you ask.

- `./build.d`: Executables here will run just before those in
  `/opt/odoo/common/build.d`.

- `./conf.d`: Files here will be environment-variable-expanded and concatenated
  in `/opt/odoo/auto/odoo.conf` at build time.

- `./src`: Here you will put the actual source code for your project.

  - `./odoo` **(required)**: The source code for your odoo project.

  - `./private` **(required)**: Folder with private addons for the project.

  - `./repos.yaml`: A
    [git-aggregator](https://pypi.python.org/pypi/git-aggregator)
    configuration file.

  - `./addons.txt`: One line per addon you want to activate in your project.
    Like this:

        server-tools/*
        website/website_legal_page

    Important notes:

    - You do not need to add addons for the required directories above, those
    are automatic.
    - Any other addon not listed here will not be usable in Odoo (and removed
      by default).
    - In case of addon name conflict, this is the importance order in which
      they will be linked (from most to least important):
      1. Addons in `./private`.
      2. Custom addons listed in `./addons.txt`.
      3. Core Odoo addons from `./odoo/addons`.

Keep in mind that when putting code inside `./src`, you can either:

- Use `./repos.yaml`, that will fill anything at build time.
- Directly copy all there.

Recommendation: use `./repos.yaml` for everything except for `./private`.

Also, when putting code inside `./{build,entrypoint}.d`, remember that
non-executable files and those with a `.` in their name will not be executed.

### `/opt/odoo/common`: The useful one

This folder is full of magic. I'll document it some day. For now, just look at
the code.

Only some notes:

- Will compile your code with `PYTHONOPTIMIZE=2` by default.
- Will remove all code not used from the image by default (not listed in
  `/opt/odoo/custom/src/addons.txt`), to keep it thin.

### `/opt/odoo/auto`: The automatic one

This directory will have things that are automatically generated at build time.

Basically:

- `./addons` will be full of symlinks to the addons you selected in
  `addons.txt`.
- `./odoo.conf` will have the result of merging all configurations under
  `/opt/odoo/{common,custom}/conf.d/`, in that order.

## The `Dockerfile`

I will document all build arguments and environment variables some day, but for
now keep this in mind:

- I have put all `ENV`, `ARG`, `VOLUME`, `EXPOSE` and `ONBUILD` sentences at
  the top so you can easily see what will we have into account at each stage.

- This is just a base image, full of tools. You need to build your project
  subimage from this one, even if your project's `Dockerfile` only contains
  these 2 lines:

      FROM tecnativa/odoo-base
      MAINTAINER Me <me@example.com>

- The above sentence becomes true because we have a lot of `ONBUILD` sentences
  here, so at least **your project must have a `./custom` folder** along with
  its `Dockerfile` for it to work.

- All should be magic if you adhere to our opinions here. Just put the code
  where it should go, and relax.

## Bundled tools

### `log`

Just a little shell script that you can use to add logs to your build or
entrypoint scripts:

    log INFO I'm informing

### `unittest`

Another little shell script, useful for debugging. Just run it like this and
Odoo will execute unit tests in its default database:

    unittest my_addon,my_other_addon

### [`psql`](https://www.postgresql.org/docs/9.5/static/app-psql.html)

Environment variables are there so that if you need to connect with the
database, you just need to execute:

    docker exec -it your_container psql

### [`wdb`](https://github.com/Kozea/wdb/)

In our opinion, this is the greatest Python debugger available, mostly for
Docker-based development, so here you have it preinstalled.

I told you, this image is opinionated :wink:.

**DO NOT USE IT IN PRODUCTION ENVIRONMENTS.** (I had to say it).

### `git-aggregator`

We found this one to be the most useful tool for downlading code and placing it
somewhere.

We use [our own fork](https://github.com/Tecnativa/git-aggregator) because it
is even better! (Until they merge some PRs and publish a new version).

Actually, because [it allows you to choose a `--depth` when pulling
images](https://github.com/acsone/git-aggregator/pull/7), and [fetches only the
required remotes](https://github.com/acsone/git-aggregator/pull/6).

### [`odoo.py`](https://www.odoo.com/documentation/9.0/reference/cmdline.html)

We set an `$ODOO_RC` environment variable pointing to the autogenerated
configuration file so you don't have to worry about it. Just execute `odoo.py`
and it will work fine.
