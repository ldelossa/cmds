#!/bin/bash
kubectl --namespace ${1} logs --timestamps ${2} 2>&1 | bat --theme=base16 -llog
