#!/bin/bash
kubectl describe --all-namespaces pods -l ${1}
