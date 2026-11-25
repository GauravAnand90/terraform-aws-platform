# ADR 0002: Remote state in S3 with native lockfile locking

**Status:** Accepted

## Context

State has to be shared between engineers and CI, locked during writes, recoverable after a mistake, and never public.

The long-standing pattern was S3 for state plus a DynamoDB table for locks. Since Terraform 1.10, the S3 backend can lock with a lock object in the bucket itself (`use_lockfile = true`), and DynamoDB-based locking is deprecated.

## Decision

- One S3 bucket per account, created by `bootstrap/`, named with the account ID so it's globally unique.
- **Native S3 locking** (`use_lockfile = true`). No DynamoDB table.
- **Versioning on**, with noncurrent versions expired after 90 days, so any bad apply can be rolled back by restoring the previous state version.
- **SSE-KMS encryption**, all public access blocked, and a bucket policy that denies non-TLS requests.
- The bucket name is passed at `init` (`-backend-config="bucket=..."`), so no account ID is committed to the repo.

## Consequences

- One less resource to manage and pay for.
- Requires Terraform >= 1.10, which every root pins with `required_version`.
- The bootstrap stack keeps local state. It's tiny, rarely changes, and `prevent_destroy` guards the bucket.
