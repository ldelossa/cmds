#!/bin/bash

commit="${1}"
git branch --contains "${commit}"
