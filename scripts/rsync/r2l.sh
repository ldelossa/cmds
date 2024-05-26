#!/bin/bash
rsync -e ssh --mkpath --delete -azv "$1":"$(pwd)" "$(pwd)"/
