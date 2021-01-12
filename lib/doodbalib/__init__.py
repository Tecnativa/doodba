# -*- coding: utf-8 -*-
import logging
import os
from glob import glob
from pprint import pformat
from subprocess import check_output

import yaml

# Constants needed in scripts
CUSTOM_DIR = "/opt/odoo/custom"
AUTO_DIR = "/opt/odoo/auto"
ADDONS_DIR = os.path.join(AUTO_DIR, "addons")
SRC_DIR = os.path.join(CUSTOM_DIR, "src")

ADDONS_YAML = os.path.join(SRC_DIR, "addons")
if os.path.isfile("%s.yaml" % ADDONS_YAML):
    ADDONS_YAML = "%s.yaml" % ADDONS_YAML
else:
    ADDONS_YAML = "%s.yml" % ADDONS_YAML

REPOS_YAML = os.path.join(SRC_DIR, "repos")
if os.path.isfile("%s.yaml" % REPOS_YAML):
    REPOS_YAML = "%s.yaml" % REPOS_YAML
else:
    REPOS_YAML = "%s.yml" % REPOS_YAML

AUTO_REPOS_YAML = os.path.join(AUTO_DIR, "repos")
if os.path.isfile("%s.yml" % AUTO_REPOS_YAML):
    AUTO_REPOS_YAML = "%s.yml" % AUTO_REPOS_YAML
else:
    AUTO_REPOS_YAML = "%s.yaml" % AUTO_REPOS_YAML

CLEAN = os.environ.get("CLEAN") == "true"
LOG_LEVELS = frozenset({"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"})
FILE_APT_BUILD = os.path.join(CUSTOM_DIR, "dependencies", "apt_build.txt")
PRIVATE = "private"
CORE = "odoo/addons"
ENTERPRISE = "enterprise"
PRIVATE_DIR = os.path.join(SRC_DIR, PRIVATE)
CORE_DIR = os.path.join(SRC_DIR, CORE)
ODOO_DIR = os.path.join(SRC_DIR, "odoo")
ODOO_VERSION = os.environ["ODOO_VERSION"]
MANIFESTS = ("__manifest__.py", "__openerp__.py")
if ODOO_VERSION in {"8.0", "9.0"}:
    MANIFESTS = MANIFESTS[1:]

# Customize logging for build
logger = logging.getLogger("doodba")
log_handler = logging.StreamHandler()
log_formatter = logging.Formatter("%(name)s %(levelname)s: %(message)s")
log_handler.setFormatter(log_formatter)
logger.addHandler(log_handler)
_log_level = os.environ.get("LOG_LEVEL", "")
if _log_level.isdigit():
    _log_level = int(_log_level)
elif _log_level in LOG_LEVELS:
    _log_level = getattr(logging, _log_level)
else:
    if _log_level:
        logger.warning("Wrong value in $LOG_LEVEL, falling back to INFO")
    _log_level = logging.INFO
logger.setLevel(_log_level)


class AddonsConfigError(Exception):
    def __init__(self, message, *args):
        super(AddonsConfigError, self).__init__(message, *args)
        self.message = message


def addons_config(filtered=True, strict=False):
    """Yield addon name and path from ``ADDONS_YAML``.

    :param bool filtered:
        Use ``False`` to include all addon definitions. Use ``True`` (default)
        to include only those matched by ``ONLY`` clauses, if any.

    :param bool strict:
        Use ``True`` to raise an exception if any declared addon is not found.

    :return Iterator[str, str]:
        A generator that yields ``(addon, repo)`` pairs.
    """
    config = dict()
    missing_glob = set()
    missing_manifest = set()
    all_globs = {}
    try:
        with open(ADDONS_YAML) as addons_file:
            for doc in yaml.safe_load_all(addons_file):
                # Skip sections with ONLY and that don't match
                only = doc.pop("ONLY", {})
                if not filtered:
                    doc.setdefault(CORE, ["*"])
                    doc.setdefault(PRIVATE, ["*"])
                elif any(
                    os.environ.get(key) not in values for key, values in only.items()
                ):
                    logger.debug("Skipping section with ONLY %s", only)
                    continue
                # Flatten all sections in a single dict
                for repo, partial_globs in doc.items():
                    if repo == "ENV":
                        continue
                    logger.debug("Processing %s repo", repo)
                    all_globs.setdefault(repo, set())
                    all_globs[repo].update(partial_globs)
    except IOError:
        logger.debug("Could not find addons configuration yaml.")
    # Add default values for special sections
    for repo in (CORE, PRIVATE):
        all_globs.setdefault(repo, {"*"})
    logger.debug("Merged addons definition before expanding: %r", all_globs)
    # Expand all globs and store config
    for repo, partial_globs in all_globs.items():
        for partial_glob in partial_globs:
            logger.debug("Expanding in repo %s glob %s", repo, partial_glob)
            full_glob = os.path.join(SRC_DIR, repo, partial_glob)
            found = glob(full_glob)
            if not found:
                # Projects without private addons should never fail
                if (repo, partial_glob) != (PRIVATE, "*"):
                    missing_glob.add(full_glob)
                logger.debug("Skipping unexpandable glob '%s'", full_glob)
                continue
            for addon in found:
                if not os.path.isdir(addon):
                    continue
                manifests = (os.path.join(addon, m) for m in MANIFESTS)
                if not any(os.path.isfile(m) for m in manifests):
                    missing_manifest.add(addon)
                    logger.debug(
                        "Skipping '%s' as it is not a valid Odoo " "module", addon
                    )
                    continue
                logger.debug("Registering addon %s", addon)
                addon = os.path.basename(addon)
                config.setdefault(addon, set())
                config[addon].add(repo)
    # Fail now if running in strict mode
    if strict:
        error = []
        if missing_glob:
            error += ["Addons not found:", pformat(missing_glob)]
        if missing_manifest:
            error += ["Addons without manifest:", pformat(missing_manifest)]
        if error:
            raise AddonsConfigError("\n".join(error), missing_glob, missing_manifest)
    logger.debug("Resulting configuration after expanding: %r", config)
    for addon, repos in config.items():
        # Private addons are most important
        if PRIVATE in repos:
            yield addon, PRIVATE
            continue
        # Odoo core addons are least important
        if repos == {CORE}:
            yield addon, CORE
            continue
        repos.discard(CORE)
        # Other addons fall in between
        if filtered and len(repos) != 1:
            raise AddonsConfigError(
                u"Addon {} defined in several repos {}".format(addon, repos)
            )
        for repo in repos:
            yield addon, repo


try:
    from shutil import which
except ImportError:
    # Custom which implementation for Python 2
    def which(binary):
        return check_output(["which", binary]).strip()
