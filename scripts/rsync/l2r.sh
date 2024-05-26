#!/bin/bash
rsync -e ssh --mkpath --delete -azv "$(pwd)"/ "$1":"$(pwd)"

