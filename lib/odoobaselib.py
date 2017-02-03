# -*- coding: utf-8 -*-
import logging
import os

import yaml

# Constants needed in scripts
SRC_DIR = "/opt/odoo/custom/src"
ADDONS_YAML = SRC_DIR + "/addons.yaml"
ADDONS_DIR = "/opt/odoo/auto/addons"
CLEAN = os.environ.get("CLEAN") == "yes"
LINK = os.environ.get("LINK") == "yes"

# Allow to change log level for build
logging.root.setLevel(int(os.environ.get("LOG_LEVEL", logging.INFO)))


def addons_config():
    """Load configurations from ``ADDONS_YAML`` into a dict."""
    config = dict()
    with open(ADDONS_YAML) as addons_file:
        for doc in yaml.load_all(addons_file):
            for repo, addons in doc.items():
                if addons == "all":
                    config[repo] = addons
                else:
                    config.setdefault(repo, list())
                    config[repo] += addons

    return config
