#!/usr/bin/env python
# Copyright (c) 2019 ACSONE SA/NV
# Distributed under the MIT License (http://opensource.org/licenses/MIT)

from __future__ import print_function

import os
import sys

import requests

CHUNK_SIZE = 2 ** 16


class Error(Exception):
    pass


class UsageError(Error):
    pass


class ServerError(Error):
    pass


def wkhtmltopdf(args):
    url = os.getenv("KWKHTMLTOPDF_SERVER_URL")

    if url == "":
        raise UsageError("KWKHTMLTOPDF_SERVER_URL not set")
    elif url == "MOCK":
        print("wkhtmltopdf 0.12.5 (mock)")
        return

    parts = []

    def add_option(option):
        # TODO option encoding?
        parts.append(("option", (None, option)))

    def add_file(filename):
        with open(filename, "rb") as f:
            parts.append(("file", (filename, f.read())))

    if "-" in args:
        raise UsageError("stdin/stdout input is not implemented")

    output = "-"
    if len(args) >= 2 and not args[-1].startswith("-") and not args[-2].startswith("-"):
        output = args[-1]
        args = args[:-1]

    for arg in args:
        if arg.startswith("-"):
            add_option(arg)
        elif arg.startswith("http://") or arg.startswith("https://"):
            add_option(arg)
        elif arg.startswith("file://"):
            add_file(arg[7:])
        elif os.path.isfile(arg):
            # TODO better way to detect args that are actually options
            # TODO in case an option has the same name as an existing file
            # TODO only way I see so far is enumerating them in a static
            # TODO datastructure (that can be initialized with a quick parse
            # TODO of wkhtmltopdf --extended-help)
            add_file(arg)
        else:
            add_option(arg)

    if not parts:
        add_option("-h")

    try:
        r = requests.post(url, files=parts)
        r.raise_for_status()

        if output == "-":
            if sys.version_info[0] < 3:
                out = sys.stdout
            else:
                out = sys.stdout.buffer
        else:
            out = open(output, "wb")
        for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
            out.write(chunk)
    except requests.exceptions.ChunkedEncodingError:
        # TODO look if client and server could use trailer headers
        # TODO to report errors
        raise ServerError("kwkhtmltopdf server error, consult server log")


if __name__ == "__main__":
    try:
        wkhtmltopdf(sys.argv[1:])
    except Error as e:
        print(e, file=sys.stderr)
        sys.exit(-1)
