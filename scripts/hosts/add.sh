#!/bin/bash

host=${1}
name="${2}"

printf "%s %s\n" "$host" "$name" | sudo tee -a /etc/hosts
