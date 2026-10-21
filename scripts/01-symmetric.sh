#!/usr/bin/env bash
# Part 1: symmetric encrypt / decrypt with key "symmetric-key"
# Prereq: key ring and key created (console steps in docs/cloud-kms-guide.md)
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
cd "${WORKDIR}"

echo "Welcome to Cloud KMS Demo" > test.txt

gcloud kms encrypt \
  --key symmetric-key --keyring "${KEYRING}" --location "${LOCATION}" \
  --plaintext-file test.txt --ciphertext-file encrypt.txt

gcloud kms decrypt \
  --key symmetric-key --keyring "${KEYRING}" --location "${LOCATION}" \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt

diff test.txt decrypt.txt && echo "Round trip OK"
