# rds-aurora

Aurora PostgreSQL cluster (provisioned or Serverless v2) that only the security groups you name can reach.

## Design choices

- **No password in Terraform state.** `manage_master_user_password` has RDS generate the password, store it in Secrets Manager and rotate it.
- **Customer-managed KMS key** for storage, Performance Insights and the master secret.
- **TLS forced** (`rds.force_ssl = 1`), slow queries over 1s logged, and DDL logged for audits.
- **Security-group-to-security-group ingress only**, with no CIDR rules, on the isolated database subnets.
- **Enhanced Monitoring** (60s by default) for OS-level metrics that CloudWatch alone doesn't show.
- **Writer + reader by default** (`instance_count = 2`) so failover takes seconds, not a full instance rebuild.
- **IAM database authentication** enabled for short-lived app credentials.
- **Deletion protection and final snapshot on by default.** You have to opt out explicitly, and only dev does.
- Backup and maintenance windows set to low-traffic hours for US Pacific.

## Usage

```hcl
module "aurora" {
  source = "../../modules/rds-aurora"

  name                       = "platform-prod"
  engine_version             = "16.4"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.database_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.r6g.large"
  instance_count             = 2
  backup_retention_days      = 14
}
```

Serverless v2:

```hcl
  instance_class        = "db.serverless"
  serverless_v2_scaling = { min_capacity = 0.5, max_capacity = 4 }
```

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `name` | Cluster identifier | `string` | required |
| `engine_version` | Aurora PostgreSQL version | `string` | required |
| `vpc_id` | VPC ID | `string` | required |
| `subnet_ids` | Database subnets | `list(string)` | required |
| `allowed_security_group_ids` | SGs allowed on 5432 | `list(string)` | `[]` |
| `database_name` | Initial database | `string` | `"app"` |
| `master_username` | Master user | `string` | `"platform_admin"` |
| `instance_class` | Instance class or `db.serverless` | `string` | `"db.r6g.large"` |
| `instance_count` | Writer + readers | `number` | `2` |
| `serverless_v2_scaling` | ACU range for Serverless v2 | `object` | `null` |
| `backup_retention_days` | PITR window | `number` | `7` |
| `deletion_protection` | Block deletes | `bool` | `true` |
| `monitoring_interval` | Enhanced Monitoring seconds | `number` | `60` |
| `skip_final_snapshot` | Skip snapshot on destroy | `bool` | `false` |
| `tags` | Common tags | `map(string)` | `{}` |

## Outputs

`cluster_id`, `writer_endpoint`, `reader_endpoint`, `port`, `master_user_secret_arn`, `security_group_id`
