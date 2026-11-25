# eks

EKS cluster with managed node groups, built with security defaults that usually get added only after an audit finding.

## Design choices

- **Private API endpoint by default.** The public endpoint is opt-in and limited to CIDRs you list.
- **Access entries (`authentication_mode = "API"`)** instead of the `aws-auth` ConfigMap: access is managed in Terraform and IAM, and a bad ConfigMap edit can't lock everyone out. The cluster creator gets no hidden admin rights.
- **KMS envelope encryption** for Kubernetes secrets, with key rotation.
- **IMDSv2 required, hop limit 1** on nodes, so pods can't steal the node's IAM credentials.
- **No SSH keys.** Nodes get `AmazonSSMManagedInstanceCore` for Session Manager access.
- **Pod Identity agent** installed for workload IAM, with the OIDC provider kept for IRSA-only tools.
- **Control plane audit logs** go to CloudWatch with a set retention.
- **`desired_size` ignored after creation** so Terraform doesn't fight the cluster autoscaler or Karpenter.
- **Rolling node updates** at 33% max unavailable.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name         = "platform-dev"
  kubernetes_version   = "1.33"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  admin_principal_arns = ["arn:aws:iam::123456789012:role/PlatformAdmin"]

  node_groups = {
    general = {
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `cluster_name` | Cluster name | `string` | required |
| `kubernetes_version` | Control plane minor version | `string` | required |
| `vpc_id` | VPC ID | `string` | required |
| `subnet_ids` | Private subnets for ENIs and nodes | `list(string)` | required |
| `node_groups` | Managed node groups (instance types, sizes, labels, taints, SPOT/ON_DEMAND) | `map(object)` | required |
| `endpoint_public_access` | Public API endpoint | `bool` | `false` |
| `public_access_cidrs` | CIDRs for the public endpoint | `list(string)` | `[]` |
| `admin_principal_arns` | IAM principals given cluster-admin | `list(string)` | `[]` |
| `control_plane_log_types` | Control plane logs to ship | `list(string)` | `["api","audit","authenticator"]` |
| `log_retention_days` | Log retention | `number` | `30` |
| `tags` | Common tags | `map(string)` | `{}` |

## Outputs

`cluster_name`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_security_group_id`, `oidc_provider_arn`, `node_role_arn`
