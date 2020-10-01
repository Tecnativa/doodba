#!/usr/local/bin/python-odoo-shell
# -*- coding: utf-8 -*-

# python-odoo-shell is deprecated

try:
    from odoo.tools import config
except ImportError:
    from openerp.tools import config

assert config.get("email_from") == "test@example.com"
assert config.get("limit_memory_soft") == 2097152000
assert config.get("smtp_password") is False
assert config.get("smtp_port") == 1025
assert config.get("smtp_server") == "mailhog"
assert config.get("smtp_ssl") is False
assert config.get("smtp_user") is False
assert config.get("dbfilter") == ".*"
