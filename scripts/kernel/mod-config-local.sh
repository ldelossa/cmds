#!/bin/bash
lsmod > /tmp/lsmod.now
yes "" | make LSMOD=/tmp/lsmod.now localmodconfig
