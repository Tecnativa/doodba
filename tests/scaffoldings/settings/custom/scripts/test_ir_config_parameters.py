#!/usr/bin/env python
# -*- coding: utf-8 -*-

import click
import click_odoo


@click.command()
@click_odoo.env_options(default_log_level="error")
def main(env):
    """Set report.url in the database to be pointing at localhost."""
    assert env["ir.config_parameter"].get_param("report.url") == "http://localhost:8069"


if __name__ == "__main__":
    main()
