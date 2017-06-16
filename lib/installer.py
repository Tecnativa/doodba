# -*- coding: utf-8 -*-

import logging
import os
import subprocess


class Installer(object):
    """ Install all sorts of things. """

    def __init__(self, handler_name, file_path):
        self.handler_name = handler_name
        self.file_path = file_path
        self.requirements = self._parse_requirements()

    def install(self):
        install_handler = '_install_%s' % self.handler_name
        getattr(self, install_handler)()

    def remove(self):
        remove_handler = '_remove_%s' % self.handler_name
        getattr(self, remove_handler)()

    def _install_apt(self):
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
        self._run_command(
            'apt-get -y autoremove',
        )
        self._run_command(
            'rm -Rf /var/lib/apt/lists/*',
        )

    def _remove_apt(self):
        for requirement in self.requirements:
            self._run_command(
                'apt-get purge -y %s' % requirement,
            )

    def _install_gem(self):
        self._install_requirements(
            'gem install --no-rdoc --no-ri --no-update-sources',
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
        if split:
            command = command.split()
        logging.debug('Running Command: %s', command)
        if shell:
            proc = subprocess.Popen(
                ' '.join(command),
                env=os.environ,
                shell=True,
            )
        else:
            proc = subprocess.Popen(command, env=os.environ)
        proc.communicate()

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
