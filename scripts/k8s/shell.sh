#!/bin/bash
shell=$3
if [[ -z $shell ]]; then
	shell='/bin/bash'
fi
echo $shell
kubectl --namespace ${1} exec -i -t ${2} ${shell}
