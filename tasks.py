# -*- coding: utf-8 -*-
"""Doodba maintenance tasks.

These tasks are to be executed with https://www.pyinvoke.org/ in Python 3.8.1+
"""
from pathlib import Path

from invoke import task

TEMPLATE_ROOT = Path(__file__).parent.resolve()
ESSENTIALS = ("git", "uv", "docker")


@task()
def develop(c):
    """Set up a development environment."""
    failures = []
    for dependency in ESSENTIALS:
        try:
            c.run(f"{dependency} --version", hide=True)
        except Exception:
            failures.append(dependency)
    if failures:
        print(f"Missing essential dependencies: {failures}")
    with c.cd(str(TEMPLATE_ROOT)):
        c.run("uv sync", echo=True)
        c.run("uv run pre-commit install", echo=True)


@task(
    help={
        "version": "Odoo version to build, defaults to 18.0",
        "tag": "Docker image tag, defaults to ghcr.io/tecnativa/doodba",
        "onbuild": "If false builds only abse image, defaults to True",
    }
)
def build(c, version="18.0", tag="ghcr.io/tecnativa/doodba", onbuild=True):
    """Builds the docker image"""
    args = [
        f"--file {version}.Dockerfile",
        f"--tag {tag}:{version}{'-onbuild' if onbuild else ''}",
        f"--target {'onbuild' if onbuild else 'base'}",
    ]
    with c.cd(str(TEMPLATE_ROOT)):
        c.run(f"docker build {' '.join(args)} .", echo=True)


@task()
def test(c, odoo_version="18.0", pg_version="16", failfast=False, tests="tests"):
    """Tests a single odoo version"""
    flags = ["--verbose"]
    if failfast:
        flags.append("--failfast")
    else:
        cmd = f"uv run python -m unittest { " ".join(flags)} {tests}"
    with c.cd(str(TEMPLATE_ROOT)):
        c.run(
            cmd,
            env={
                "ODOO_MINOR": odoo_version,
                "DOCKER_TAG": odoo_version,
                "PG_VERSIONS": pg_version,
            },
            echo=True,
        )


@task()
def lint(c, verbose=False):
    """Lint & format source code."""
    flags = ["--show-diff-on-failure", "--all-files", "--color=always"]
    if verbose:
        flags.append("--verbose")
    flags = " ".join(flags)
    with c.cd(str(TEMPLATE_ROOT)):
        c.run(f"uv run pre-commit run {flags}", echo=True)
