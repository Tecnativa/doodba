# -*- coding: utf-8 -*-
import os

import yaml

# Constants needed in scripts
SRC_DIR = "/opt/odoo/custom/src"
ADDONS_YAML = SRC_DIR + "/addons.yaml"
ADDONS_DIR = "/opt/odoo/auto/addons"
CLEAN = os.environ.get("CLEAN") == "yes"


def addons_config():
    """Load configurations from ``ADDONS_YAML`` into a dict."""
    with open(ADDONS_YAML) as addons_file:
        docs = yaml.load_all(addons_file)

    config = dict()
    for doc in docs:
        for repo, addons in doc.items():
            if addons == "all":
                config[repo] = addons
            else:
                config.setdefault(repo, list())
                config[repo] += addons

    return config
