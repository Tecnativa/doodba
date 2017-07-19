#!/usr/bin/env python3
"""Run tests for this base image.

Each test must be a valid docker-compose.yaml file with a ``odoo`` service.
"""
import tempfile
import unittest

from glob import iglob
from itertools import product, starmap
from os import environ
from os.path import basename, dirname, join
from subprocess import Popen

# Common test utilities
DIR = dirname(__file__)
SCAFFOLDINGS_DIR = join(DIR, "scaffoldings")
ODOO_PREFIX = ("odoo", "--stop-after-init")

# Variable matrix
ODOO_VERSIONS = frozenset((
    "10.0",
    "9.0",
    "8.0",
))
PG_VERSIONS = frozenset((
    "9.6",
))


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
            product(("ODOO_MINOR",), odoo ^ odoo_skip),
            product(("DB_VERSION",), pg ^ pg_skip),
        )
    )


class ScaffoldingLookupCase(unittest.TestCase):
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
                build = Popen(
                    ("docker-compose", "build"),
                    cwd=workdir,
                    env=full_env,
                )
                self.assertFalse(build.wait())
                for command in commands:
                    with self.subTest(command=command):
                        run = Popen(
                            ("docker-compose", "run", "--rm", "odoo") +
                            command,
                            cwd=workdir,
                            env=full_env,
                        )
                        self.assertFalse(run.wait())
            finally:
                down = Popen(
                    ("docker-compose", "down", "-v"),
                    cwd=workdir,
                    env=full_env,
                )
                self.assertFalse(down.wait())

    def test_smallest(self):
        """Tests for the smallest possible environment."""
        common_commands = (
            # Must generate a configuration file
            ("test", "-f", "/opt/odoo/auto/odoo.conf"),
            # Must be able to install base addons
            ODOO_PREFIX + ("--init", "base"),
            # Must be able to test successfully base addons
            ("unittest", "base"),
        )
        for sub_env in matrix():
            if sub_env["ODOO_VERSION"] == "8.0":
                commads = (
                    # Odoo 8.0 does not autocreate the database
                    ("psql", "-d", "postgres", "-c", "create database prod"),
                ) + common_commands
            else:
                commads = common_commands
            self.compose_test(
                join(SCAFFOLDINGS_DIR, "smallest"), sub_env, **commads)

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
                ("grep", "test-conf", "/opt/odoo/auto/odoo.conf"),
                # ``dummy_addon`` and ``private_addon`` exist
                ("test", "-d", "/opt/odoo/auto/addons/dummy_addon"),
                ("test", "!", "-d", "/opt/odoo/auto/addons/private_addon"),
                ("test", "-d", "/opt/odoo/common/src/private/dummy_addon"),
                # ``odoo`` command works
                ("odoo", "--help"),
            )

    def test_main_scaffolding(self):
        """Test the official scaffolding."""
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Clone main scaffolding
            clone = Popen(
                ("git", "clone", "-b", "scaffolding", "--depth", "1",
                 "https://github.com/Tecnativa/docker-odoo-base.git"),
                cwd=tmpdirname,
            )
            self.assertFalse(clone.wait())
            # Create inverseproxy_shared network
            net = Popen(
                ("docker", "network", "create", "inverseproxy_shared")
            )
            self.assertFalse(net.wait())
            tmpdirname = join(tmpdirname, "docker-odoo-base")
            setup = Popen(
                ("docker-compose", "-f", "setup-devel.yaml",
                 "run", "--rm", "odoo"),
                cwd=tmpdirname,
            )
            self.assertFalse(setup.wait())
            # TODO Test all supported versions
            for sub_env in matrix(odoo={"10.0"}):
                # Setup the devel environment
                sub_env["COMPOSE_FILE"] = "setup-devel.yaml"
                self.compose_test(tmpdirname, sub_env, ())
                # Test all 3 official environments
                for dcfile in ("devel", "test", "prod"):
                    sub_env["COMPOSE_FILE"] = f"{dcfile}.yaml"
                    self.compose_test(
                        tmpdirname, sub_env,
                        # ``odoo`` command works
                        ("odoo", "--help"),
                    )


if __name__ == "__main__":
    unittest.main()
