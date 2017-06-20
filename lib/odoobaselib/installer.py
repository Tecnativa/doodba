# -*- coding: utf-8 -*-

import logging

from odoobaselib import do_command

INSTALLERS = ('apt', 'gem', 'npm', 'pip')
CLEANERS = ('apt', 'gem', 'npm')


class Installer(object):
    """Install all sorts of things."""
    _has_run = {}

    def __init__(self, handler_name, file_path):
        self.handler_name = handler_name
        self.file_path = file_path
        self.requirements = self._parse_requirements()

    def has_run(self, install_type, update=True):
        has_run = self._has_run.get(install_type, False)
        if update:
            self._has_run[install_type] = True
        return has_run

    def install(self):
        install_handler = '_install_%s' % self.handler_name
        getattr(self, install_handler)()

    def remove(self):
        remove_handler = '_remove_%s' % self.handler_name
        getattr(self, remove_handler)()

    def cleanup(self):
        remove_handler = '_cleanup_%s' % self.handler_name
        getattr(self, remove_handler)()

    def _cleanup_apt(self):
        self._run_command(
            'apt-get -y autoremove',
        )
        self._run_command(
            'rm -Rf /var/lib/apt/lists/*',
        )

    def _install_apt(self):
        if not self.has_run('apt'):
            self._run_command(
                'apt-get update',
            )
        self._install_requirements([
            'apt-get',
            '-o', 'Dpkg::Options::="--force-confdef"',
            '-o', 'Dpkg::Options::="--force-confold"',
            '-y', '--no-install-recommends', 'install',
        ],
            split=False,
            shell=True,
        )

    def _remove_apt(self):
        for requirement in self.requirements:
            self._run_command(
                'apt-get purge -y %s' % requirement,
            )

    def _cleanup_gem(self):
        self._run_command(
            'rm -Rf ~/.gem /var/lib/gems/*/cache/',
        )

    def _install_gem(self):
        self._install_requirements(
            'gem install --no-rdoc --no-ri --no-update-sources',
        )

    def _cleanup_npm(self):
        self._run_command(
            'rm -Rf ~/.npm /tmp/*',
        )

    def _install_npm(self):
        self._run_command(
            'npm install -g',
        )

    def _install_pip(self):
        self._install_requirements(
            'pip --no-cache-dir install',
        )

    def _install_requirements(self, command, split=True, shell=False):
        if split:
            command = command.split()
        for requirement in self.requirements:
            self._run_command(
                command + [requirement],
                split=False,
                shell=shell,
            )

    def _run_command(self, command, split=True, shell=False):
        logging.info("Executing: %s", command)
        return do_command(command, split, shell)

    def _parse_requirements(self):
        requirements = []
        with open(self.file_path, 'r') as fh:
            for line in fh.read().splitlines():
                if line.strip().startswith('#'):
                    continue
                requirements += [
                    req.strip() for req in line.split() if req.strip()
                ]
        return requirements
