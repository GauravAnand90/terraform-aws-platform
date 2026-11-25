# ADR 0001: Repository layout. Modules plus one root per environment

**Status:** Accepted

## Context

We need dev and prod built from the same code, with different sizes and risk settings, and a blast radius small enough that a bad dev change can't touch prod state.

Options considered:

1. **Terraform workspaces** with one root and `terraform.workspace` conditionals.
2. **Terragrunt** to keep environments DRY.
3. **Reusable modules + a thin root per environment** (`envs/dev`, `envs/prod`), each with its own state file.

## Decision

Option 3.

- Each environment has **its own state key**, so a corrupted or locked dev state never blocks prod.
- Differences between environments live in `terraform.tfvars`. The root `main.tf` files are identical, which a reviewer can confirm with a single `diff`.
- Plain Terraform keeps onboarding simple: no extra tool, and nothing hidden in workspace conditionals.
- Modules are versioned with the repo today. When another team consumes them, they move to their own repo with semver tags.

## Consequences

- `main.tf` and `variables.tf` are duplicated across environments. We accept that for clarity; CI validates both.
- If the platform grows to many accounts and regions, Terragrunt or Terraform Stacks would be worth revisiting.
