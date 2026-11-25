# ADR 0004: EKS version upgrades

**Status:** Accepted

## Context

EKS versions get about 14 months of standard support. After that, clusters move to extended support at a much higher control-plane price. Skipping upgrades also stacks up API removals, which turns a routine upgrade into a project.

## Decision

- `upgrade_policy.support_type = "STANDARD"`, so we never pay for extended support without noticing.
- Upgrade **one minor version at a time**, **dev first**, with prod following after at least a week of soak time.
- The upgrade order, every time:
  1. Check for deprecated APIs (`kubent` or `pluto`) and the EKS upgrade insights tab.
  2. Bump `kubernetes_version` in `envs/dev/terraform.tfvars` and open a PR. The plan shows the control-plane upgrade.
  3. After apply, managed node groups roll at 33% max unavailable. PodDisruptionBudgets keep services up.
  4. Managed add-ons (`vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent`) are updated to versions compatible with the new control plane.
  5. Repeat for prod.

## Consequences

- At most two upgrades a year per cluster, each a small, reviewed PR.
- Workloads must define PodDisruptionBudgets and readiness probes. This is a platform requirement documented for app teams.
