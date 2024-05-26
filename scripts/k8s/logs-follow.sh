#!/bin/bash
kubectl --namespace ${1} logs --follow --timestamps ${2} 2>&1 | bat --theme=base16 -llog
