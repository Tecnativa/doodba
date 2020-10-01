#!/usr/bin/env python
# -*- coding: utf-8 -*-
from click import command
from click_odoo import env_options, odoo


@command()
@env_options(default_log_level="error")
def main(env):
    config = odoo.tools.config
    assert config.get("email_from") == "test@example.com"
    assert config.get("limit_memory_soft") == 2097152000
    assert config.get("smtp_password") is False
    assert config.get("smtp_port") == 1025
    assert config.get("smtp_server") == "mailhog"
    assert config.get("smtp_ssl") is False
    assert config.get("smtp_user") is False
    assert config.get("dbfilter") == ".*"


if __name__ == "__main__":
    main()
