#!/bin/sh
# Thanks Camptocamp for the idea!
# http://www.camptocamp.com/en/actualite/flexible-docker-entrypoints-scripts/
set -e

mode=$(basename $0 .sh)

for dir in custom common; do
    dir=/opt/odoo/$dir/$mode.d
    if [ -d $dir ]; then
        log INFO Executing contents of $dir > /dev/stderr
        run-parts --exit-on-error $dir
    else
        log WARNING Skipping execution of $dir: not found
    fi
done

if [ -n "$1" ]; then
    set -x
    exec "$@"
fi
