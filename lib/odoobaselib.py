# -*- coding: utf-8 -*-
import logging
import os

import yaml

# Constants needed in scripts
SRC_DIR = "/opt/odoo/custom/src"
ADDONS_YAML = SRC_DIR + "/addons.yaml"
ADDONS_DIR = "/opt/odoo/auto/addons"
CLEAN = os.environ.get("CLEAN") == "true"
LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR")

# Customize logging for build
logging.root.name = "docker-odoo-base"
_log_level = os.environ.get("LOG_LEVEL", "")
if _log_level.isdigit():
    _log_level = int(_log_level)
elif _log_level in LOG_LEVELS:
    _log_level = getattr(logging, _log_level)
else:
    _log_level = logging.INFO
    logging.warning("Wrong value in $LOG_LEVEL, falling back to INFO")
logging.root.setLevel(_log_level)


def addons_config():
    """Load configurations from ``ADDONS_YAML`` into a dict."""
    config = dict()
    with open(ADDONS_YAML) as addons_file:
        for doc in yaml.load_all(addons_file):
            for repo, addons in doc.items():
                config.setdefault(repo, list())
                config[repo] += addons

    return config
