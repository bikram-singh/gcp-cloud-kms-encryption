#!/usr/bin/env bash
# Part 4: MAC sign / verify with "mac-key" (HMAC SHA-256). Symmetric, so no public key.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
mkdir -p "${WORKDIR}/MAC-sign" && cd "${WORKDIR}/MAC-sign"

echo "This is the MAC signing demo" > mac-sign

gcloud kms mac-sign \
  --version 1 --key mac-key --keyring "${KEYRING}" --location "${LOCATION}" \
  --input-file mac-sign --signature-file mac.txt

echo "--- verify original (expect: True)"
gcloud kms mac-verify \
  --version 1 --key mac-key --keyring "${KEYRING}" --location "${LOCATION}" \
  --input-file mac-sign --signature-file mac.txt

echo "--- verify altered copy (expect: not True)"
cp mac-sign mac-sign-altered && echo "Altered File" >> mac-sign-altered
gcloud kms mac-verify \
  --version 1 --key mac-key --keyring "${KEYRING}" --location "${LOCATION}" \
  --input-file mac-sign-altered --signature-file mac.txt || true
