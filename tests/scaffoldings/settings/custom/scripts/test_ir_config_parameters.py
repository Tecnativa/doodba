#!/usr/bin/env python
# -*- coding: utf-8 -*-

import click
import click_odoo


@click.command()
@click_odoo.env_options(default_log_level="error")
def main(env):
    """Set report.url in the database to be pointing at localhost."""
    config_parameter = env["ir.config_parameter"]
    if "set_param" in dir(config_parameter):
        get_method = config_parameter.get_param
    else:
        get_method = config_parameter.get_str
    assert get_method("report.url") == "http://localhost:8069"


if __name__ == "__main__":
    main()
