#!/usr/bin/env bash

SVC_PLATFORM=${SVC_PLATFORM:-platform}

set -ex

cd "$SVC_PLATFORM"
vagrant destroy --force
