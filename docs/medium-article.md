<!--
PUBLISHING NOTES
Each "Show Image ..." line is an image placeholder. Upload the matching file in Medium:
 - Table images: docs/article/01..08 (01 Key Facts, 02 What Makes This Different, 03 Benefits, 04 Four keys, 05 What was built, 06 Key purpose, 07 Gotchas, 08 Observations)
 - Architecture: docs/snapshots/00-architecture/gcp-cloud-kms-architecture.png
 - Screenshots: docs/snapshots/01..09-*/ (names match the captions)
-->

# GCP Cloud KMS Explained With Real Demos

### Encryption, Key Rotation, CMEK, Digital Signatures and MAC

**GCP · Cloud KMS · Encryption · CMEK · Digital Signatures · MAC · Cloud Security**

A practical walkthrough of Google Cloud KMS, built from scratch and proved with real commands: symmetric encryption, key rotation and key versions, a Cloud Storage bucket protected with a customer-managed key, what happens when you disable that key, asymmetric encryption, digital signatures and MAC signatures. Every step is backed by screenshots from the GCP Console and Cloud Shell.

Show Image GCP Cloud KMS architecture: one key ring, four keys, and the steps (including the failures) for each

---

## 📖 Introduction

Google already encrypts your data at rest by default, and you never touch those keys. That is enough for many workloads. Sooner or later, though, a security review asks the same question: *who controls the encryption keys?*

Cloud KMS is the answer. It lets you create and manage your own keys, decide who can use them, rotate them on a schedule, and switch them off. It powers customer-managed encryption keys (CMEK) for Cloud Storage, BigQuery, Cloud SQL and more. You can also call it directly to encrypt data, sign files and verify integrity.

KMS keys come in four flavours, and the docs describe them separately. I wanted to see them side by side, so I built one lab that uses all four, including the failures: the wrong key version, a disabled key, a tampered file. This article is that build, step by step.

## 🔑 Key Facts

Show Image Key Facts

## ✨ What Makes This Different

Show Image What Makes This Different

## 💡 Why customer-managed keys: the benefits, mapped to what I built

Show Image Why customer-managed keys: the benefits mapped to what I built

## 🏛️ Architecture

```
                   Project (Cloud KMS API enabled) · us-central1
  ┌────────────────────────────────────────────────────────────────────────┐
  │ Key ring: test-ring                                                    │
  │                                                                        │
  │  🔑 symmetric-key           Symmetric encrypt/decrypt · 90-day rotation │
  │       ├── gcloud kms encrypt / decrypt   (Cloud Shell)                 │
  │       └── CMEK ──► Cloud Storage bucket: cloud-kms-demo-bucket         │
  │                                                                        │
  │  🔐 asymmetric-key-decrypt  RSA 3072 · OAEP · SHA-256                  │
  │       ├── public key ──► openssl encrypt  (local, no KMS call)         │
  │       └── private key stays in KMS ──► gcloud kms asymmetric-decrypt   │
  │                                                                        │
  │  ✍️ asymmetric-sign         EC P-256 · SHA-256                         │
  │       ├── gcloud kms asymmetric-sign    (private key, in KMS)          │
  │       └── public key ──► openssl dgst -verify  (anyone can verify)     │
  │                                                                        │
  │  🧾 mac-key                 HMAC · SHA-256  (symmetric, no public key) │
  │       └── gcloud kms mac-sign / mac-verify                             │
  └────────────────────────────────────────────────────────────────────────┘
```

Four keys, four different jobs. Here is how they compare:

Show Image The four keys compared

## 🧠 The concepts you need (five minutes of theory)

**Key ring.** A group of keys in one location. It cannot be deleted, so name it deliberately.

**Key and key version.** A key is a named object with a purpose and one or more versions. The version holds the actual key material, and is enabled, disabled, scheduled for destruction or destroyed.

**Purpose.** Chosen when you create the key and never changed. It decides which operations the key supports: symmetric encrypt/decrypt, asymmetric decrypt, asymmetric sign or MAC.

**Primary version.** A symmetric key has one primary version, which is used for new encryption. **Asymmetric keys have no primary version**, so every operation must name the version.

**CMEK.** Customer-managed encryption keys: your KMS key used by a Google Cloud service to protect your data. The service reaches the key through its own service agent, which needs permission.

**Rotation.** Creates a new version for new data. It does **not** re-encrypt old data.

**Symmetric vs asymmetric.** Symmetric uses one shared secret for both directions. Asymmetric uses a public/private pair: the public key can be shared freely, and the private key never leaves KMS. A MAC is symmetric too, which becomes important in Part 9.

**Protection levels.** Software (what I used), HSM for FIPS 140-2 Level 3 hardware, and External for keys held in your own external key manager.

## 🔄 The build order

```
 Enable API ──► Key ring ──► Symmetric key ──► Encrypt / Decrypt ──► Rotate
                                  │
                                  ▼
                 CMEK bucket (same location + service-agent role)
                                  │
                                  ▼
                   Disable key ──► data unreadable ──► re-enable
                                  │
                                  ▼
 Asymmetric key ──► public key ──► openssl encrypt ──► KMS decrypt (by version)
                                  │
                                  ▼
     Signing key ──► sign in KMS ──► verify with openssl ──► tamper ──► fails
                                  │
                                  ▼
                MAC key ──► mac-sign ──► mac-verify ──► alter ──► fails ✅
```

## 🔹 Part 1: Enable the API and create the key ring

I used a free-trial project and Cloud Shell for every command. First, enable the Cloud KMS API, either from the Marketplace page or with `gcloud services enable cloudkms.googleapis.com`.

Show Image Enabling the Cloud KMS API

Then, under **Security → Key Management**, create the key ring `test-ring` in `us-central1`.

Show Image Creating the key ring

🔍 **Key behavior I found.** The key ring is tied to its location and cannot be deleted later. Pick the name and the location on purpose.

## 🔹 Part 2: The symmetric key

Inside `test-ring`, I created a key with these settings:

- Name: `symmetric-key`
- Protection level: Software (HSM and External are the other choices)
- Key material: Generated
- Purpose: Symmetric encrypt/decrypt
- Rotation: every 90 days
- Scheduled destruction: 10 days

Show Image Key name and protection level

Show Image Symmetric purpose and algorithm

Show Image The rotation summary spells out the schedule

Show Image Scheduled destruction set to 10 days

The result is a key that shows as **Available**.

Show Image The key is available in the key ring

Equivalent CLI, for reference (I used the console for the build, so check the flags against `--help` before relying on them):

```bash
gcloud kms keyrings create test-ring --location us-central1

gcloud kms keys create symmetric-key \
  --keyring test-ring --location us-central1 \
  --purpose encryption \
  --rotation-period 90d \
  --next-rotation-time "$(date -u -d '+90 days' +%Y-%m-%dT%H:%M:%SZ)" \
  --destroy-scheduled-duration 10d
```

🔍 **Key behaviors I found**

**The destruction delay is your safety net.** When a key version is destroyed it waits in *scheduled for destruction* for that many days, and you can still restore it. I shortened it to 10 days for the demo. Think twice before doing that in production.

**Choosing External changes the form.** Picking External as the protection level asks for an EKM connection type (via internet or via VPC), because the key lives in a key manager you run. That needs setup I did not do here.

## 🔹 Part 3: Encrypt and decrypt

In Cloud Shell, I created a test file and encrypted it:

```bash
mkdir -p ~/KMS-demo && cd ~/KMS-demo
echo "Welcome to Cloud KMS Demo" > test.txt

gcloud kms encrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --plaintext-file test.txt --ciphertext-file encrypt.txt
```

Show Image encrypt.txt is unreadable binary

Decrypting returns the original text:

```bash
gcloud kms decrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt

cat decrypt.txt
# Welcome to Cloud KMS Demo
```

Show Image Decrypting gives back the original text

🔍 **Key behavior I found.** I never passed a key version. KMS reads it from the ciphertext when decrypting, and uses the primary version when encrypting. That matters in the next part.

## 🔹 Part 4: Rotating the key

Rotation creates a new key version and makes it primary, so new data uses fresh key material. On the key's **Versions** tab, click **Rotate key**.

Show Image The rotate dialog explains what will happen

After rotating, version 2 is **Enabled & primary** and version 1 stays **Enabled**.

Show Image Version 2 is primary, version 1 is still enabled

Now the real test. `encrypt.txt` was created with version 1. I decrypted it again after rotation:

```bash
gcloud kms decrypt \
  --key symmetric-key --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt-2.txt

cat decrypt-2.txt
# Welcome to Cloud KMS Demo
```

Show Image Old ciphertext still decrypts after rotation

🔍 **Key behaviors I found**

**Rotation does not re-encrypt old data.** The dialog says it plainly: older versions can still decrypt, and data encrypted with them is not re-encrypted unless you do it yourself. Rotation is about what *new* data uses.

**Primary only controls new encryption.** You can open any enabled version's menu and choose *Make primary version*. It changes which version new encryption uses, and nothing else.

## 🔹 Part 5: CMEK on a Cloud Storage bucket

This is the real use case. I created `cloud-kms-demo-bucket` and, under **Data encryption**, chose **Cloud KMS key**, then picked `symmetric-key`.

**Gotcha 1: location.** My key is in `us-central1`. When I first tried a bucket in `us-east1`, the key picker said *No valid keys found*, with the filter showing the purpose and the location. A CMEK key must be in the same location as the resource.

Show Image Key in us-central1, bucket in us-east1: no valid keys

**Gotcha 2: the service agent.** With the right region and key selected, the console warned that the Cloud Storage service agent did not have the `cloudkms.cryptoKeyEncrypterDecrypter` role on the key. I clicked **Grant**.

Show Image Granting the service agent access to the key

Once the bucket was created, the **Protection** section showed *Customer-managed*, with a link to the key.

Show Image The bucket uses a customer-managed key

I uploaded two objects, and each one reported its own key version:

Show Image Object details name the exact key version used

🔍 **Key behaviors I found**

**A missing service-agent grant is the most common CMEK failure.** The console flags it with a **Grant** button, so read that warning before you click Create.

**Object details show the exact key version.** The object was encrypted with `cryptoKeyVersions/2`, the primary version at upload time. So the version you rotate to is the version your data actually uses.

## 🔹 Part 6: The kill switch

This is why people choose CMEK. I disabled both key versions on the **Versions** tab, and the key status flipped to **Not available**.

Show Image With both versions disabled the key is not available

Encrypting from the CLI now failed with `FAILED_PRECONDITION`, because the key version is `DISABLED`.

Show Image gcloud kms encrypt fails on a disabled key

And opening the object in the bucket returned this:

> Cloud KMS key is disabled, destroyed, or scheduled to be destroyed.

Show Image The object cannot be read while the key is disabled

🔍 **Key behavior I found.** Disabling is reversible: enable the versions again and access returns. Destroying is not, once the scheduled delay passes. Treat key disable and destroy events as alert-worthy.

## 🔹 Part 7: Asymmetric encryption

With asymmetric keys there is a **key pair**. The public key encrypts and can be shared with anyone. The private key decrypts and never leaves KMS.

I created `asymmetric-key-decrypt` with purpose **Asymmetric decrypt** and algorithm **3072 bit RSA - OAEP Padding - SHA256 Digest**. The console states that automatic rotation is not available for asymmetric keys.

Show Image Asymmetric decrypt with RSA 3072 and OAEP

To encrypt, you first need the public key. On the **Versions** tab, open the action menu and choose **Get public key**, then download it. The CLI does the same:

```bash
gcloud kms keys versions get-public-key 1 \
  --key asymmetric-key-decrypt --keyring test-ring --location us-central1 \
  --output-file test-ring-asymmetric-key-decrypt-1.pub
```

Show Image Get public key from the version's action menu

Encryption happens locally with OpenSSL. KMS is not involved at all, which is the point:

```bash
openssl pkeyutl -in test.txt -encrypt -pubin \
  -inkey test-ring-asymmetric-key-decrypt-1.pub \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -pkeyopt rsa_mgf1_md:sha256 \
  > encrypt.txt
```

Show Image Encrypting with the public key using OpenSSL

Decryption has to go through KMS. Because there is no primary version, I must say which one:

```bash
gcloud kms asymmetric-decrypt \
  --version 1 \
  --key asymmetric-key-decrypt --keyring test-ring --location us-central1 \
  --ciphertext-file encrypt.txt --plaintext-file decrypt.txt
```

To see why that matters, I created a second version of the key. Both versions are enabled, and neither is labelled primary.

Show Image Two versions and no primary

`encrypt.txt` was encrypted with the version 1 public key. Decrypting with `--version 2` failed:

```
ERROR: (gcloud.kms.asymmetric-decrypt) INVALID_ARGUMENT: Decryption failed.
```

Show Image The wrong version fails

Switching back to `--version 1` worked.

Show Image The right version decrypts the file

🔍 **Key behaviors I found**

**Asymmetric ciphertext is bound to a version.** It only decrypts with the key pair whose public key encrypted it. Store the key version next to the ciphertext.

**The OpenSSL options must match the key.** OAEP with SHA-256 for both the digest and the MGF1 function, to match the algorithm I chose when creating the key.

## 🔹 Part 8: Digital signatures

A digital signature answers two questions: *who produced this?* and *was it changed?* The signer uses the private key inside KMS. Anyone with the public key can verify.

I created `asymmetric-sign` with purpose **Asymmetric sign** and algorithm **Elliptic Curve P-256 - SHA256 Digest**, then downloaded its public key the same way as before.

Show Image Signing key: Elliptic Curve P-256 with SHA-256

Sign in KMS, verify anywhere with OpenSSL:

```bash
gcloud kms asymmetric-sign \
  --version 1 \
  --key asymmetric-sign --keyring test-ring --location us-central1 \
  --digest-algorithm sha256 \
  --input-file test.txt --signature-file sign.txt

openssl dgst -sha256 \
  -verify test-ring-asymmetric-sign-1.pub \
  -signature sign.txt test.txt
```

The output is `Verified OK`.

Show Image The signature verifies with the public key

Then I appended one line to `test.txt` and ran the same verify command:

```
Verification failure
```

Show Image One changed line breaks the signature

🔍 **Key behavior I found.** In practice, you publish the file, the signature and your public key. Anyone can then check that the file is yours and unmodified. The same pattern secures binaries, container images and tokens.

## 🔹 Part 9: MAC signatures

A MAC gives you integrity and authenticity too, but with a **shared secret** instead of a key pair. Both sender and receiver call KMS with the same key.

I created `mac-key` with purpose **MAC signing/verification** and algorithm **HMAC - SHA256 Digest**. Then I looked at the version's action menu: *Disable*, *Destroy* and *Copy resource name*, but no *Get public key*.

Show Image No Get public key option on a MAC key

Signing and verifying:

```bash
gcloud kms mac-sign \
  --version 1 \
  --key mac-key --keyring test-ring --location us-central1 \
  --input-file mac-sign --signature-file mac.txt

gcloud kms mac-verify \
  --version 1 \
  --key mac-key --keyring test-ring --location us-central1 \
  --input-file mac-sign --signature-file mac.txt
```

The verify command printed `True`.

Show Image MAC verification returns True

After I edited the file and verified again, the result was no longer `True` (the CLI printed `None`), so the change was caught.

Show Image Altered file: the MAC check fails

🔍 **Key behaviors I found**

**A MAC key has no public key.** It is symmetric, so there is nothing to publish. That is the practical difference from a digital signature: only parties who can call KMS with that key can create or verify the tag.

**Two ways to prove a file was not altered.** Share the MAC tag and let the other side verify it, or regenerate the file from the same source and run `diff`. The second only works when you can reproduce the file.

## 🧭 Which key purpose should you use?

Show Image Which key purpose should you use

## 🧾 Cheat sheet: gotchas worth remembering

Show Image Cheat sheet: gotchas worth remembering

## 🕵️ Observations from the build

These came up while building it, not from the docs:

Show Image Observations from the build

## 🔒 Security habits worth adopting

- 🧑‍⚖️ **Separate duties:** `cloudkms.admin` manages keys but cannot use them. `cloudkms.cryptoKeyEncrypterDecrypter` uses them but cannot manage them.
- 🏗️ **Use a dedicated KMS project** for key rings, apart from your workloads.
- 📜 **Turn on Data Access audit logs** for Cloud KMS to see every encrypt and decrypt call.
- 🚨 **Alert on key disable and destroy events.**
- ⏳ **Keep a destruction delay** long enough to recover from mistakes.

## 💰 Cost and cleanup

Keys are not free to leave around. Active key versions are billed, and so are key operations and the bucket. Check the official [Cloud KMS pricing page](https://cloud.google.com/kms/pricing) before leaving a lab like this up.

To clean up:

- Delete the demo bucket and its objects: `gsutil rm -r gs://cloud-kms-demo-bucket`
- Destroy the key versions you no longer need
- Remove the local files: `rm -rf ~/KMS-demo`

Key rings and keys stay in the project afterwards. Only their versions are destroyed.

## 🔐 A note on secrets

The screenshots show the demo project, so replace the project ID with your own if you follow along. Use throwaway files such as `test.txt`, and never commit keys, ciphertext or real secrets. If you publish a build like this, blur anything sensitive in your screenshots, such as project IDs, organization IDs and email addresses.

## 📸 Snapshots

All 50 screenshots from this build, sorted by step, are in the repository under `docs/snapshots/`.

## 🎯 Wrapping up

Show Image What was built and proved

The mental model is simple: pick the purpose first, then everything else follows. Symmetric keys encrypt and power CMEK. Asymmetric keys encrypt for outsiders and sign for everyone. MAC keys check integrity between trusted parties. The hard part is rarely a single command. It is the details around them: the key location, the service-agent permission, the key version you must remember, and what disabling a key does to your data.

Natural next steps:

- **Terraform it.** The console is great for learning, and production needs repeatability.
- **Enforce CMEK.** Use organization policies to require customer-managed keys for chosen services.
- **Try HSM or External keys** if your compliance needs call for hardware or your own key manager.
- **Automate key creation** with Cloud KMS Autokey so developers are not waiting on a security team.

If you are working with Cloud KMS, give this a try in a throwaway project before it goes near production.

## 🔗 Repository

🔑 **gcp-cloud-kms-encryption:** https://github.com/bikram-singh/gcp-cloud-kms-encryption
