# Cloud KMS on GCP, Hands-On: Encrypt, Rotate, Sign and Verify With Your Own Keys

*Subtitle: A practical walkthrough of symmetric encryption, asymmetric encryption, digital signatures and MAC signatures in Google Cloud KMS, with every command and screenshot.*

**Tags:** Google Cloud, Cloud KMS, Encryption, Cloud Security, DevOps

---

Almost every cloud security review asks the same question: *who controls the encryption keys?* On Google Cloud the answer is Cloud KMS. It is the service behind customer-managed encryption keys (CMEK) for Cloud Storage, BigQuery, Cloud SQL and many other services, and you can also call it directly for your own encryption, signing and integrity checks.

Reading the docs only takes you so far. In this post I walk through a lab I ran end to end, with real screenshots and commands:

- **Symmetric encryption**, including key rotation, key versions and CMEK on a Cloud Storage bucket
- **Asymmetric encryption**, and why the key version matters
- **Digital signatures**, including detecting a tampered file
- **MAC signatures**, and why a MAC key has no public key

Everything is on GitHub: **https://github.com/bikram-singh/gcp-cloud-kms-encryption**

## Cloud KMS in one minute

Cloud KMS lets you create and manage encryption keys for Google Cloud services and your own applications. You can generate software or HSM keys, import your own key material, or point to a key held in an external key manager. You can also use KMS keys to create and verify digital signatures and message authentication codes (MACs).

Google already encrypts everything at rest by default, and you do not manage those keys. Customer-managed keys are for cases where you need control: who can use the key, when it rotates, and the ability to switch access off.

The building blocks are simple:

- **Key ring:** a group of keys in one location. It cannot be deleted.
- **Key:** a named object with a **purpose** (fixed at creation) and one or more **versions**.
- **Key version:** the actual key material. A version is enabled, disabled, scheduled for destruction or destroyed.
- **Primary version:** the version a symmetric key uses for new encryption. **Asymmetric keys have no primary version.**

The purpose decides everything you can do with a key:

- Symmetric encrypt/decrypt: `encrypt` and `decrypt`
- Asymmetric decrypt: `getPublicKey` and `asymmetricDecrypt`
- Asymmetric sign: `getPublicKey` and `asymmetricSign`
- MAC signing/verification: `macSign` and `macVerify`

## Setup

I used a free-trial project, the location `us-central1`, a key ring called `test-ring`, and Cloud Shell for every command. First enable the API:

```bash
gcloud services enable cloudkms.googleapis.com
```

![Enabling the Cloud KMS API](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/01-enable-kms-api.png)
*Enabling the Cloud KMS API*

## Part 1: Symmetric encryption

### Create the key ring and key

In *Security → Key Management*, create the key ring `test-ring` in `us-central1`. Then create a key with these settings:

- Name: `symmetric-key`
- Protection level: Software (HSM and External are the other choices)
- Key material: Generated
- Purpose: Symmetric encrypt/decrypt
- Rotation: every 90 days
- Scheduled destruction: 10 days (the default is 30)

![Key name and protection level](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/03-key-name-and-protection-level.png)
*Key name and protection level*

![Symmetric purpose and algorithm](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/07-symmetric-purpose-and-algorithm.png)
*Symmetric purpose and algorithm*

![The scheduled destruction delay protects you from accidental deletes](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/10-scheduled-destruction-delay-10-days.png)
*The scheduled destruction delay protects you from accidental deletes*

That last setting matters more than it looks. When you destroy a key version it waits in *scheduled for destruction* for that many days, and you can still restore it.

### Encrypt and decrypt

```bash
echo "Welcome to Cloud KMS Demo" > test.txt

gcloud kms encrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --plaintext-file test.txt --ciphertext-file encrypt.txt

gcloud kms decrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt
```

`cat encrypt.txt` is unreadable, and `cat decrypt.txt` gives the original text. Notice that you never pass a version. KMS reads it from the ciphertext.

![Encrypting a file with gcloud kms encrypt](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/02-symmetric-encrypt-decrypt/01-encrypt-with-gcloud.png)
*Encrypting a file with gcloud kms encrypt*

![Decrypting returns the original text](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/02-symmetric-encrypt-decrypt/02-decrypt-with-gcloud.png)
*Decrypting returns the original text*

### Rotate the key

Rotation creates a new key version and makes it primary, so **new** data uses fresh key material. On the key's *Versions* tab, click *Rotate key*.

![The rotate dialog spells out what happens](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/02-rotate-key-dialog.png)
*The rotate dialog spells out what happens*

Read that dialog carefully: older versions can still decrypt, and data encrypted with them is **not** re-encrypted. To prove it, I decrypted the same `encrypt.txt` (made with version 1) after rotation:

```bash
gcloud kms decrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt-2.txt
```

It worked. Version 2 is primary, version 1 is still enabled, and KMS routes the ciphertext to the right version.

![Version 2 is primary, version 1 stays enabled](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/03-version-2-enabled-and-primary.png)
*Version 2 is primary, version 1 stays enabled*

![Old ciphertext still decrypts after rotation](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/04-decrypt-old-ciphertext-after-rotation.png)
*Old ciphertext still decrypts after rotation*

You can also pick any enabled version from its action menu and choose *Make primary version*.

![Changing the primary version](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/05-make-version-1-primary.png)
*Changing the primary version*

### Use the key for a Cloud Storage bucket (CMEK)

Now the real use case. I created `cloud-kms-demo-bucket` and, under *Data encryption*, chose *Cloud KMS key*.

**Gotcha 1: location.** My key is in `us-central1`. When I first tried a bucket in `us-east1`, the key picker said *No valid keys found*, with the filter showing the purpose and the location. A CMEK key must be in the same location as the resource.

![Key in us-central1, bucket in us-east1: no valid keys](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/01-bucket-region-mismatch-no-valid-keys.png)
*Key in us-central1, bucket in us-east1: no valid keys*

**Gotcha 2: the service agent.** After picking the right region and key, the console warned that the Cloud Storage service agent did not have `cloudkms.cryptoKeyEncrypterDecrypter` on the key. Click *Grant*. A missing service-agent binding is the single most common reason CMEK setups fail.

![Grant the service agent access to the key](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/02-grant-service-agent-encrypter-decrypter.png)
*Grant the service agent access to the key*

Once created, the bucket's *Protection* section shows *Customer-managed* with a link to the key. I uploaded two objects, and the *Encryption* column showed *Customer-managed* for both. The object details even name the exact key version used, here `cryptoKeyVersions/2`.

![Bucket encryption type: Customer-managed](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/03-bucket-encryption-customer-managed.png)
*Bucket encryption type: Customer-managed*

![Object details show the key version that encrypted it](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/05-object-details-key-version.png)
*Object details show the key version that encrypted it*

### The kill switch: disable the key

This is why people choose CMEK. I disabled both key versions. The key status flipped to *Not available*.

![All versions disabled, the key is not available](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/02-key-status-not-available.png)
*All versions disabled, the key is not available*

Encrypting from the CLI now fails with `FAILED_PRECONDITION`, because the key version is `DISABLED`. And opening the object in the bucket returns:

> Cloud KMS key is disabled, destroyed, or scheduled to be destroyed.

![gcloud kms encrypt fails on a disabled key](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/01-disabled-versions-encrypt-fails.png)
*gcloud kms encrypt fails on a disabled key*

![The object cannot be read while the key is disabled](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/03-object-download-blocked.png)
*The object cannot be read while the key is disabled*

Disable is reversible: re-enable the versions and access returns. Destroy is not, once the scheduled delay passes. Treat key disable and destroy events as alert-worthy.

## Part 2: Asymmetric encryption

With asymmetric keys there is a **key pair**. The public key encrypts and can be shared with anyone. The private key decrypts and never leaves KMS.

I created `asymmetric-key-decrypt` with purpose *Asymmetric decrypt* and algorithm *3072 bit RSA - OAEP Padding - SHA256 Digest*. Notice the console says automatic rotation is not available for asymmetric keys.

![Asymmetric decrypt with RSA 3072 and OAEP](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/06-asymmetric-key-creation/02-asymmetric-decrypt-rsa-3072-oaep.png)
*Asymmetric decrypt with RSA 3072 and OAEP*

To encrypt, you first need the public key. On the *Versions* tab, open the action menu and choose *Get public key*, then download it (or use `gcloud kms keys versions get-public-key`).

![Get public key from the version's action menu](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/06-asymmetric-key-creation/05-versions-get-public-key.png)
*Get public key from the version's action menu*

Encryption happens locally with OpenSSL. KMS is not involved at all, which is the point:

```bash
openssl pkeyutl -in test.txt -encrypt -pubin \
  -inkey test-ring-asymmetric-key-decrypt-1.pub \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -pkeyopt rsa_mgf1_md:sha256 \
  > encrypt.txt
```

![Encrypting with the public key using OpenSSL](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/02-openssl-encrypt-with-public-key.png)
*Encrypting with the public key using OpenSSL*

Decryption must go through KMS, and because there is no primary version you must say which one:

```bash
gcloud kms asymmetric-decrypt \
  --version 1 \
  --key asymmetric-key-decrypt --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt
```

### Why the version matters

I created a second version of the key. Both versions are enabled, and neither is labelled primary.

![Two versions, no primary](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/05-two-key-versions.png)
*Two versions, no primary*

`encrypt.txt` was encrypted with the version 1 public key. Decrypting with `--version 2` fails:

```
ERROR: (gcloud.kms.asymmetric-decrypt) INVALID_ARGUMENT: Decryption failed.
```

![Wrong version: decryption fails](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/06-decrypt-with-wrong-version-fails.png)
*Wrong version: decryption fails*

Switch back to `--version 1` and it works. The lesson: with asymmetric keys, store the key version next to the ciphertext.

![Correct version: decryption succeeds](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/07-decrypt-with-correct-version-works.png)
*Correct version: decryption succeeds*

## Part 3: Digital signatures

A digital signature answers two questions: *who produced this?* and *was it changed?* The signer uses the private key in KMS. Anyone with the public key can verify.

I created `asymmetric-sign` with purpose *Asymmetric sign* and algorithm *Elliptic Curve P-256 - SHA256 Digest*, and downloaded its public key the same way as before.

![Signing key: Elliptic Curve P-256 with SHA-256](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/02-asymmetric-sign-ec-p256-sha256.png)
*Signing key: Elliptic Curve P-256 with SHA-256*

Sign in KMS, verify anywhere with OpenSSL:

```bash
gcloud kms asymmetric-sign \
  --version 1 --key asymmetric-sign --keyring test-ring --location us-central1 \
  --digest-algorithm sha256 \
  --input-file test.txt --signature-file sign.txt

openssl dgst -sha256 \
  -verify test-ring-asymmetric-sign-1.pub \
  -signature sign.txt test.txt
```

Output: `Verified OK`.

![Signature verified with the public key](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/04-sign-and-verify-ok.png)
*Signature verified with the public key*

Then I appended one line to `test.txt` and ran the same verify command:

```
Verification failure
```

![A single changed line breaks the signature](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/05-tampered-file-verification-failure.png)
*A single changed line breaks the signature*

In practice, you publish the file, the signature and your public key. Anyone can check that the file is yours and unmodified. The same pattern secures binaries, container images and tokens.

## Part 4: MAC signatures

A MAC gives you integrity and authenticity too, but with a **shared secret** instead of a key pair. The sender and the receiver both call KMS with the same key. That is why **a MAC key has no public key to download**.

I created `mac-key` with purpose *MAC signing/verification* and algorithm *HMAC - SHA256 Digest*. Look at the version's action menu: *Disable*, *Destroy* and *Copy resource name*, but no *Get public key*.

![No Get public key option on a MAC key](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/02-mac-key-version-no-public-key.png)
*No Get public key option on a MAC key*

```bash
gcloud kms mac-sign \
  --version 1 --key mac-key --keyring test-ring --location us-central1 \
  --input-file mac-sign --signature-file mac.txt

gcloud kms mac-verify \
  --version 1 --key mac-key --keyring test-ring --location us-central1 \
  --input-file mac-sign --signature-file mac.txt
```

The verify command prints `True`.

![MAC verification returns True](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/04-mac-verify-true.png)
*MAC verification returns True*

After I edited the file and verified again, the result was no longer `True` (the CLI printed `None`), so the change was caught.

![Altered file: MAC verification fails](https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/05-altered-file-verify-fails.png)
*Altered file: MAC verification fails*

## Which one should you use?

- **Protecting your own data or enabling CMEK:** symmetric encrypt/decrypt.
- **Letting outsiders send you encrypted data:** asymmetric decrypt, and share the public key.
- **Proving who published something:** asymmetric sign.
- **Checking integrity between two trusted parties:** MAC.

## Lessons learned

1. **Pick the purpose first.** You cannot change it later.
2. **Rotation does not re-encrypt old data.** It only changes which version new operations use.
3. **For asymmetric keys, always track the version.** There is no primary version to fall back on.
4. **For CMEK, check location and service-agent access first.** Those two cause most failures.
5. **Disabling a key stops access immediately.** Build alerting around disable and destroy events, and keep a sensible destruction delay.
6. **Separate duties.** `cloudkms.admin` manages keys but cannot use them, and `cloudkms.cryptoKeyEncrypterDecrypter` uses them but cannot manage them. Keep keys in a dedicated project and turn on Data Access audit logs.
7. **Key rings and keys cannot be deleted**, so name them carefully. Destroy the demo key versions when you finish, since active versions are billed.

## Try it yourself

The full step-by-step guide, every screenshot and the demo scripts are in the repository:

**https://github.com/bikram-singh/gcp-cloud-kms-encryption**

If this was useful, follow me for more hands-on GCP, security and DevOps labs.

