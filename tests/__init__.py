#!/usr/bin/env python3
"""Run tests for this base image.

Each test must be a valid docker-compose.yaml file with a ``odoo`` service.
"""
import logging
import tempfile
import unittest

from glob import iglob
from itertools import product, starmap
from os import environ, getlogin
from os.path import basename, dirname, join
from pwd import getpwnam
from subprocess import PIPE, Popen

logging.basicConfig(level=logging.DEBUG)

MAIN_SCAFFOLDING_VERSION = "10.0"
DIR = dirname(__file__)
ODOO_PREFIX = ("odoo", "--stop-after-init", "--workers=0")
ODOO_VERSIONS = frozenset(environ.get(
    "DOCKER_TAG", "8.0 9.0 10.0 11.0").split())
PG_VERSIONS = frozenset(environ.get(
    "PG_VERSIONS", "9.6").split())
SCAFFOLDINGS_DIR = join(DIR, "scaffoldings")


def matrix(odoo=ODOO_VERSIONS, pg=PG_VERSIONS,
           odoo_skip=frozenset(), pg_skip=frozenset()):
    """All possible combinations.

    We compute the variable matrix here instead of in ``.travis.yml`` because
    this generates faster builds, given the scripts found in ``hooks``
    directory are already multi-version-build aware.
    """
    return map(
        dict,
        product(
            product(("ODOO_MINOR",), ODOO_VERSIONS & odoo - odoo_skip),
            product(("DB_VERSION",), PG_VERSIONS & pg - pg_skip),
        )
    )


class ScaffoldingCase(unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.compose_run = ("docker-compose", "run", "--rm", "odoo")

    def popen(self, *args, **kwargs):
        """Shortcut to open a subprocess and ensure it works."""
        logging.info("Subtest execution: %s", self._subtest)
        self.assertFalse(Popen(*args, **kwargs).wait())

    def compose_test(self, workdir, sub_env, *commands):
        """Execute commands in a docker-compose environment.

        :param workdir:
            Path where the docker compose commands will be executed. It should
            contain a valid ``docker-compose.yaml`` file.

        :param dict sub_env:
            Specific environment variables that will be appended to current
            ones to execute the ``docker-compose`` tests.

            You can set in this dict a ``COMPOSE_FILE`` key to choose different
            docker-compose files in the same directory.

        :param tuple()... commands:
            List of commands to be tested in the odoo container.
        """
        full_env = dict(environ, **sub_env)
        with self.subTest(PWD=workdir, **sub_env):
            try:
                self.popen(
                    ("docker-compose", "build"),
                    cwd=workdir,
                    env=full_env,
                )
                for command in commands:
                    with self.subTest(command=command):
                        self.popen(
                            self.compose_run + command,
                            cwd=workdir,
                            env=full_env,
                        )
            finally:
                self.popen(
                    ("docker-compose", "down", "-v"),
                    cwd=workdir,
                    env=full_env,
                )

    def test_addons_filtered(self):
        """Test addons filtering with ``ONLY`` keyword in ``addons.yaml``."""
        project_dir = join(SCAFFOLDINGS_DIR, "dotd")
        for sub_env in matrix(odoo={"10.0"}):
            self.compose_test(
                project_dir,
                dict(sub_env, DBNAME="prod"),
                ("test", "-e", "auto/addons/website"),
                ("test", "-e", "auto/addons/dummy_addon"),
                ("test", "-e", "auto/addons/private_addon"),
                ("bash", "-c", 'test "$(addons-install -lp)" == private_addon'),
                ("bash", "-c", 'test "$(addons-install -le)" == dummy_addon'),
                ("bash", "-c", 'addons-install -lc | grep ,crm,'),
            )
            self.compose_test(
                project_dir,
                dict(sub_env, DBNAME="limited_private"),
                ("test", "-e", "auto/addons/website"),
                ("test", "-e", "auto/addons/dummy_addon"),
                ("test", "!", "-e", "auto/addons/private_addon"),
                ("bash", "-c", 'test -z "$(addons-install -lp)"'),
                ("bash", "-c", 'test "$(addons-install -le)" == dummy_addon'),
                ("bash", "-c", 'addons-install -lc | grep ,crm,'),
            )
            self.compose_test(
                project_dir,
                dict(sub_env, DBNAME="limited_core"),
                ("test", "!", "-e", "auto/addons/website"),
                ("test", "-e", "auto/addons/dummy_addon"),
                ("test", "!", "-e", "auto/addons/private_addon"),
                ("bash", "-c", 'test -z "$(addons-install -lp)"'),
                ("bash", "-c", 'test "$(addons-install -le)" == dummy_addon'),
                ("bash", "-c", 'test "$(addons-install -lc)" == crm,sale'),
            )

    def test_smallest(self):
        """Tests for the smallest possible environment."""
        commands = (
            # Must generate a configuration file
            ("test", "-f", "/opt/odoo/auto/odoo.conf"),
            ("test", "-d", "/opt/odoo/custom/src/private"),
            ("test", "-d", "/opt/odoo/custom/ssh"),
            ("test", "-x", "/usr/local/bin/unittest"),
            # Must be able to install base addon
            ODOO_PREFIX + ("--init", "base"),
            # Auto updater must work
            ("autoupdate",),
        )
        smallest_dir = join(SCAFFOLDINGS_DIR, "smallest")
        for sub_env in matrix(odoo_skip={"8.0"}):
            self.compose_test(smallest_dir, sub_env, *commands)
        for sub_env in matrix(odoo={"8.0"}):
            self.compose_test(
                smallest_dir, sub_env,
                # Odoo 8.0 does not autocreate the database
                ("psql", "-d", "postgres", "-c", "create database prod"),
                *commands
            )

    def test_dotd(self):
        """Test environment with common ``*.d`` directories."""
        for sub_env in matrix():
            self.compose_test(
                join(SCAFFOLDINGS_DIR, "dotd"), sub_env,
                # ``custom/build.d`` was properly executed
                ("test", "-f", "/home/odoo/created-at-build"),
                # ``custom/entrypoint.d`` was properly executed
                ("test", "-f", "/home/odoo/created-at-entrypoint"),
                # ``custom/conf.d`` was properly concatenated
                ("grep", "test-conf", "auto/odoo.conf"),
                # ``custom/dependencies`` were installed
                ("test", "!", "-e", "/usr/bin/gcc"),
                ("test", "!", "-e", "/var/lib/apt/lists/lock"),
                ("busybox", "whoami"),
                ("bash", "-c", "echo $NODE_PATH"),
                ("node", "-e", "require('test-npm-install')"),
                ("aloha_world",),
                ("python", "-c", "import Crypto; print(Crypto.__version__)"),
                ("sh", "-c", "rst2html.py --version | grep 'Docutils 0.14'"),
                # ``dummy_addon`` and ``private_addon`` exist
                ("test", "-d", "auto/addons/dummy_addon"),
                ("test", "-h", "auto/addons/dummy_addon"),
                ("test", "-f", "auto/addons/dummy_addon/__init__.py"),
                ("test", "!", "-e", "custom/src/private/dummy_addon"),
                ("test", "-d", "custom/src/private/private_addon"),
                ("test", "-f", "custom/src/private/private_addon/__init__.py"),
                ("test", "-e", "auto/addons/private_addon"),
                # ``odoo`` command works
                ("odoo", "--version"),
                # Implicit ``odoo`` command also works
                ("--version",),
            )

    @unittest.skipUnless(
        MAIN_SCAFFOLDING_VERSION in ODOO_VERSIONS,
        "Main scaffolding version is not being tested")
    def test_main_scaffolding(self):
        """Test the official scaffolding."""
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Clone main scaffolding
            self.popen(
                ("git", "clone", "-b", "scaffolding", "--depth", "1",
                 "https://github.com/Tecnativa/docker-odoo-base.git"),
                cwd=tmpdirname,
            )
            # Create inverseproxy_shared network
            self.popen(
                ("docker", "network", "create", "inverseproxy_shared")
            )
            tmpdirname = join(tmpdirname, "docker-odoo-base")
            # Special env keys for setup-devel
            pwdata = getpwnam(environ["USER"])
            setup_env = {
                "COMPOSE_FILE": "setup-devel.yaml",
                # Avoid unlink permission errors
                "UID": str(pwdata.pw_uid),
                "GID": str(pwdata.pw_gid),
            }
            # TODO Test all supported versions
            for sub_env in matrix(odoo={"10.0"}):
                # Setup the devel environment
                self.compose_test(tmpdirname, dict(sub_env, **setup_env), ())
                # Travis seems to have a different UID than 1000
                if environ.get("TRAVIS"):
                    self.popen(
                        ("sudo", "chown", "1000:1000",
                         join(tmpdirname, "odoo", "auto", "addons")),
                    )
                # Test all 3 official environments
                for dcfile in ("devel", "test", "prod"):
                    sub_env["COMPOSE_FILE"] = f"{dcfile}.yaml"
                    self.compose_test(
                        tmpdirname, sub_env,
                        # ``odoo`` command works
                        ("odoo", "--version"),
                    )
                # Restore owner in Travis so directory can be removed
                if environ.get("TRAVIS"):
                    self.popen(
                        ("sudo", "chown", "-R", "{0}:{0}".format(getlogin()),
                         join(tmpdirname, "odoo", "auto", "addons")),
                    )


if __name__ == "__main__":
    unittest.main()
