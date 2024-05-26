#!/bin/bash
kubectl get --all-namespaces pods -l ${1}
