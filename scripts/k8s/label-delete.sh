#!/bin/bash
kubectl delete --all-namespaces pods -l ${1}
