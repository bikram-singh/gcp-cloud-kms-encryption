#!/usr/bin/env bash
# Shared settings. Source this file: `source scripts/00-env.sh`
export LOCATION="us-central1"
export KEYRING="test-ring"
export WORKDIR="${HOME}/KMS-demo"
mkdir -p "${WORKDIR}"
echo "Location=${LOCATION} KeyRing=${KEYRING} Workdir=${WORKDIR}"
