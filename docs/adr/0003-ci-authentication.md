# ADR 0003: CI authenticates to AWS with GitHub OIDC and split plan/apply roles

**Status:** Accepted

## Context

Long-lived AWS access keys stored as GitHub secrets are the most common cause of cloud credential leaks. They don't expire, they get copied, and rotating them is manual.

## Decision

- GitHub Actions gets **short-lived credentials through OIDC** (`aws-actions/configure-aws-credentials`). No AWS keys are stored anywhere.
- **Two roles with different trust policies:**

| Role | Who can assume it | Permissions |
|---|---|---|
| `github-terraform-plan` | Pull requests and `main` in this repo only | `ReadOnlyAccess` + state bucket read/write (for the lock file) |
| `github-terraform-apply` | Only jobs bound to the `dev` or `prod` GitHub **environment** | Admin (see below) |

- The apply role's trust policy matches `repo:<owner>/<repo>:environment:<name>`. A workflow can't apply unless it runs in a GitHub environment, and the `prod` environment requires a reviewer. **Approval is enforced by IAM, not just by convention.**
- Pull requests from forks can't assume either role.

## Consequences

- No secrets to rotate, and CloudTrail shows every CI session with the repo and run as context.
- The apply role has `AdministratorAccess` because this is a single-purpose demo account. In a shared organization it would be scoped to the services this repo manages and carry a **permissions boundary**, so it couldn't create IAM roles more powerful than itself.
