# Medium image checklist

In Medium, find each `Show Image ...` line in `medium-article-for-medium.md`, delete it, paste the URL on its own line and press Enter (Medium embeds the image). Push the repo first so the URLs resolve.


### Top

1. **GCP Cloud KMS architecture: one key ring, four keys, and the steps (including the failures) for each**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/00-architecture/gcp-cloud-kms-architecture.png

### 🔑 Key Facts

2. **Key Facts**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/01-key-facts.png

### ✨ What Makes This Different

3. **What Makes This Different**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/02-what-makes-different.png

### 💡 Why customer-managed keys: the benefits, mapped to what I built

4. **Why customer-managed keys: the benefits mapped to what I built**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/03-why-customer-managed-keys.png

### 🏛️ Architecture

5. **The four keys compared**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/04-the-four-keys.png

### 🔹 Part 1: Enable the API and create the key ring

6. **Enabling the Cloud KMS API**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/01-enable-kms-api.png
7. **Creating the key ring**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/02-create-key-ring.png

### 🔹 Part 2: The symmetric key

8. **Key name and protection level**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/03-key-name-and-protection-level.png
9. **Symmetric purpose and algorithm**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/07-symmetric-purpose-and-algorithm.png
10. **The rotation summary spells out the schedule**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/09-rotation-summary-90-days.png
11. **Scheduled destruction set to 10 days**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/10-scheduled-destruction-delay-10-days.png
12. **The key is available in the key ring**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/01-symmetric-key-creation/11-key-available-in-key-ring.png

### 🔹 Part 3: Encrypt and decrypt

13. **encrypt.txt is unreadable binary**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/02-symmetric-encrypt-decrypt/01-encrypt-with-gcloud.png
14. **Decrypting gives back the original text**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/02-symmetric-encrypt-decrypt/02-decrypt-with-gcloud.png

### 🔹 Part 4: Rotating the key

15. **The rotate dialog explains what will happen**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/02-rotate-key-dialog.png
16. **Version 2 is primary, version 1 is still enabled**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/03-version-2-enabled-and-primary.png
17. **Old ciphertext still decrypts after rotation**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/03-key-rotation/04-decrypt-old-ciphertext-after-rotation.png

### 🔹 Part 5: CMEK on a Cloud Storage bucket

18. **Key in us-central1, bucket in us-east1: no valid keys**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/01-bucket-region-mismatch-no-valid-keys.png
19. **Granting the service agent access to the key**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/02-grant-service-agent-encrypter-decrypter.png
20. **The bucket uses a customer-managed key**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/03-bucket-encryption-customer-managed.png
21. **Object details name the exact key version used**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/04-cmek-cloud-storage/05-object-details-key-version.png

### 🔹 Part 6: The kill switch

22. **With both versions disabled the key is not available**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/02-key-status-not-available.png
23. **gcloud kms encrypt fails on a disabled key**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/01-disabled-versions-encrypt-fails.png
24. **The object cannot be read while the key is disabled**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/05-key-disable-impact/03-object-download-blocked.png

### 🔹 Part 7: Asymmetric encryption

25. **Asymmetric decrypt with RSA 3072 and OAEP**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/06-asymmetric-key-creation/02-asymmetric-decrypt-rsa-3072-oaep.png
26. **Get public key from the version's action menu**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/06-asymmetric-key-creation/05-versions-get-public-key.png
27. **Encrypting with the public key using OpenSSL**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/02-openssl-encrypt-with-public-key.png
28. **Two versions and no primary**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/05-two-key-versions.png
29. **The wrong version fails**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/06-decrypt-with-wrong-version-fails.png
30. **The right version decrypts the file**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/07-asymmetric-encrypt-decrypt/07-decrypt-with-correct-version-works.png

### 🔹 Part 8: Digital signatures

31. **Signing key: Elliptic Curve P-256 with SHA-256**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/02-asymmetric-sign-ec-p256-sha256.png
32. **The signature verifies with the public key**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/04-sign-and-verify-ok.png
33. **One changed line breaks the signature**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/08-digital-signatures/05-tampered-file-verification-failure.png

### 🔹 Part 9: MAC signatures

34. **No Get public key option on a MAC key**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/02-mac-key-version-no-public-key.png
35. **MAC verification returns True**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/04-mac-verify-true.png
36. **Altered file: the MAC check fails**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/snapshots/09-mac-signatures/05-altered-file-verify-fails.png

### 🧭 Which key purpose should you use?

37. **Which key purpose should you use**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/06-which-key-purpose.png

### 🧾 Cheat sheet: gotchas worth remembering

38. **Cheat sheet: gotchas worth remembering**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/07-gotchas.png

### 🕵️ Observations from the build

39. **Observations from the build**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/08-observations.png

### 🎯 Wrapping up

40. **What was built and proved**
   https://raw.githubusercontent.com/bikram-singh/gcp-cloud-kms-encryption/main/docs/article/05-what-was-built.png
