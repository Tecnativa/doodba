#!/bin/sh
# Create a dummy X display to make it run headless
Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
pid=$!
DISPLAY=:0.0 /usr/bin/$(basename $0) $@
kill $pid
