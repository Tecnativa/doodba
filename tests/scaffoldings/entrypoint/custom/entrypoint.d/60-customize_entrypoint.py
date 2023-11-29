#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import doodbalib

doodbalib.logger.info("custom entrypoint running")
with open("/tmp/customize_entrypoint.mark.txt", "w") as fp:
    fp.write("ok\n")
doodbalib.logger.info("custom created /tmp/customize_entrypoint.mark.txt")
