#!/usr/bin/env bash
# Part 2: asymmetric encrypt (OpenSSL + public key) / decrypt (KMS) with "asymmetric-key-decrypt"
# Usage: VERSION=1 ./02-asymmetric-encrypt.sh   (VERSION is the key version used to decrypt)
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
cd "${WORKDIR}"
KEY="asymmetric-key-decrypt"
PUB="test-ring-${KEY}-1.pub"
VERSION="${VERSION:-1}"

echo "Welcome to Cloud KMS Asymmetric key demo" > test.txt

# Public key of version 1
gcloud kms keys versions get-public-key 1 \
  --key "${KEY}" --keyring "${KEYRING}" --location "${LOCATION}" --output-file "${PUB}"

# Encrypt locally with the public key (OAEP, SHA-256)
openssl pkeyutl -in test.txt -encrypt -pubin -inkey "${PUB}" \
  -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256 \
  > encrypt.txt

# Decrypt in KMS. You must name the version. Using a different version fails.
gcloud kms asymmetric-decrypt \
  --version "${VERSION}" --key "${KEY}" --keyring "${KEYRING}" --location "${LOCATION}" \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt

cat decrypt.txt
