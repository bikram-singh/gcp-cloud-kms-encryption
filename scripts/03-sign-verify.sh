#!/usr/bin/env bash
# Part 3: digital signature with "asymmetric-sign" (EC P-256, SHA-256)
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
mkdir -p "${WORKDIR}/Asymmetric-sign" && cd "${WORKDIR}/Asymmetric-sign"
KEY="asymmetric-sign"
PUB="test-ring-${KEY}-1.pub"

echo "This is Asymmetric-sign demo" > test.txt

gcloud kms keys versions get-public-key 1 \
  --key "${KEY}" --keyring "${KEYRING}" --location "${LOCATION}" --output-file "${PUB}"

gcloud kms asymmetric-sign \
  --version 1 --key "${KEY}" --keyring "${KEYRING}" --location "${LOCATION}" \
  --digest-algorithm sha256 --input-file test.txt --signature-file sign.txt

echo "--- verify original (expect: Verified OK)"
openssl dgst -sha256 -verify "${PUB}" -signature sign.txt test.txt

echo "--- verify tampered copy (expect: Verification failure)"
cp test.txt tampered.txt && echo "Tampered file" >> tampered.txt
openssl dgst -sha256 -verify "${PUB}" -signature sign.txt tampered.txt || true
