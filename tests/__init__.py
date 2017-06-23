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

# Variable matrix
ODOO_VERSIONS = (
    "10.0",
    "9.0",
    # TODO Add tests for 8.0, the problem is that it does not autocreate a DB
)
PG_VERSIONS = (
    "9.6",
)


def matrix(compose_files, odoo=ODOO_VERSIONS, pg=PG_VERSIONS):
    """All possible combinations.

    We compute the variable matrix here instead of in ``.travis.yml`` because
    this generates faster builds, given the scripts found in ``hooks``
    directory are already multi-version-build aware.
    """
    return product(
        product(("COMPOSE_FILE",), compose_files),
        product(("ODOO_MINOR",), odoo),
        product(("DB_VERSION",), pg),
    )


class ScaffoldingLookupCase(unittest.TestCase):
    def setUp(self):
        super().setUp()
        # Common tests to run in any odoo container
        _odoo = ("odoo", "--stop-after-init")
        self.commands = [
            # Must generate a configuration file
            ("test", "-f", "/opt/odoo/auto/odoo.conf"),
            # Must be able to install base addons
            _odoo + ("--init", "base"),
            # Must be able to test successfully base addons
            ("unittest", "base"),
        ]

    def docker_compose_tests(self, env_matrix):
        """Execute a docker-compose environment.

        :param generator env_matrix:
            A list of key-value pairs that conform the specific environments
            that should be tested. The current environment will be appended
            to each of those to execute the ``docker-compose`` tests.

            It is required that each sub-environment contains a
            ``COMPOSE_FILE`` key with a full path to a valid Docker Compose
            file.
        """
        for sub_env in env_matrix:
            sub_env = dict(sub_env)
            workdir = dirname(sub_env["COMPOSE_FILE"])
            sub_env["COMPOSE_FILE"] = basename(sub_env["COMPOSE_FILE"])
            full_env = dict(environ, **sub_env)
            with self.subTest(**sub_env):
                try:
                    build = Popen(
                        ("docker-compose", "build"),
                        cwd=workdir,
                        env=full_env,
                    )
                    self.assertFalse(build.wait())
                    for cmd in self.commands:
                        with self.subTest(cmd=cmd):
                            run = Popen(
                                ("docker-compose", "run", "--rm", "odoo") +
                                cmd,
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

    def test_scaffoldings(self):
        """One test per ``./scaffoldings/*.yaml`` file."""
        self.commands += [
            # ``custom/build.d`` was properly executed
            ("test", "-f", "/home/odoo/created-at-build"),
            # ``custom/entrypoint.d`` was properly executed
            ("test", "-f", "/home/odoo/created-at-entrypoint"),
            # ``custom/conf.d`` was properly concatenated
            ("grep", "test-conf", "/opt/odoo/auto/odoo.conf"),
        ]
        self.docker_compose_tests(
            matrix(iglob(join(dirname(__file__), "scaffoldings", "*.yaml")))
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
            # Setup the devel environment
            tmpdirname = join(tmpdirname, "docker-odoo-base")
            setup = Popen(
                ("docker-compose", "-f", "setup-devel.yaml",
                 "run", "--rm", "odoo"),
                cwd=tmpdirname,
            )
            self.assertFalse(setup.wait())
            self.docker_compose_tests(
                matrix(
                    starmap(
                        join,
                        product(
                            (tmpdirname,),
                            # Test all 3 official environments
                            ("devel.yaml", "test.yaml", "prod.yaml")
                        )
                    ),
                    # TODO Test all supported versions
                    # The main scaffolding is only provided in latest version
                    odoo=("10.0",)
                ),
            )


if __name__ == "__main__":
    unittest.main()
