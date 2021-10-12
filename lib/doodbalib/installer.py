# -*- coding: utf-8 -*-
from collections import OrderedDict
from os.path import exists
from subprocess import check_call

from doodbalib import logger


class Installer(object):
    """Base class to install packages with some package system."""

    _cleanup_commands = []
    _install_command = None
    _remove_command = None

    def __init__(self, file_path):
        self.file_path = file_path
        self._requirements = self.requirements()

    def _run_command(self, command):
        logger.info("Executing: %s", command)
        return check_call(command, shell=isinstance(command, str))

    def cleanup(self):
        """Remove cache and other garbage produced by the installer engine."""
        for command in self._cleanup_commands:
            self._run_command(command)

    def install(self):
        """Install the requirements from the given file."""
        if self._requirements:
            return not self._run_command(self._install_command + self._requirements)
        else:
            logger.info("No installable requirements found in %s", self.file_path)
        return False

    def remove(self):
        """Uninstall the requirements from the given file."""
        if not self._remove_command:
            return
        if self._requirements:
            self._run_command(self._remove_command + self._requirements)
        else:
            logger.info("No removable requirements found in %s", self.file_path)

    def requirements(self):
        """Get a list of requirements from the given file."""
        requirements = []
        try:
            with open(self.file_path, "r") as fh:
                for line in fh:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    requirements += line.split()
        except IOError:
            # No requirements file
            pass
        return requirements


class AptInstaller(Installer):
    _cleanup_commands = [["apt-get", "-y", "autoremove"], "rm -Rf /var/lib/apt/lists/*"]
    _install_command = [
        "apt-get",
        "-o",
        "Dpkg::Options::=--force-confdef",
        "-o",
        "Dpkg::Options::=--force-confold",
        "-y",
        "--no-install-recommends",
        "install",
    ]
    _remove_command = ["apt-get", "purge", "-y"]

    def _dirty(self):
        return exists("/var/lib/apt/lists/lock")

    def cleanup(self):
        if self._dirty():
            super(AptInstaller, self).cleanup()

    def install(self):
        if not self._dirty() and self._requirements:
            self._run_command(["apt-get", "update"])
        return super(AptInstaller, self).install()


class GemInstaller(Installer):
    _cleanup_commands = ["rm -Rf ~/.gem /var/lib/gems/*/cache/"]
    _install_command = ["gem", "install", "--no-document", "--no-update-sources"]


class NpmInstaller(Installer):
    _cleanup_commands = ["rm -Rf ~/.npm /tmp/*"]
    _install_command = ["npm", "install", "-g"]


class PipInstaller(Installer):
    _install_command = ["pip", "install", "--no-cache-dir", "-r"]

    def requirements(self):
        """Pip will use its ``--requirements`` feature."""
        return [self.file_path] if exists(self.file_path) else []


INSTALLERS = OrderedDict(
    [
        ("apt", AptInstaller),
        ("gem", GemInstaller),
        ("npm", NpmInstaller),
        ("pip", PipInstaller),
    ]
)


def install(installer, file_path):
    """Perform a given type of installation from a given file."""
    return INSTALLERS[installer](file_path).install()
