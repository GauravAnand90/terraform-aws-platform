# vpc

Three-tier VPC across N availability zones: **public** (load balancers, NAT), **private** (EKS nodes and pods) and **database** (no internet route).

## Design choices

- **Per-AZ NAT in prod, single NAT in dev** (`single_nat_gateway`). One NAT per AZ means losing an AZ doesn't take egress down with it; a single NAT saves roughly $65/month per extra gateway in dev.
- **Large private subnets.** With the VPC CNI each pod takes a VPC IP, so private subnets get `/20`s from a `/16`.
- **Isolated database tier** with its own route table and no `0.0.0.0/0` route.
- **S3 gateway endpoint** so image pulls and log shipping skip NAT data-processing charges.
- **Default security group locked down** and **flow logs on** for every VPC.
- **EKS discovery tags** (`kubernetes.io/role/elb`, `internal-elb`) added when `cluster_name` is set.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "platform-dev"
  cidr_block         = "10.10.0.0/16"
  azs                = ["us-west-2a", "us-west-2b"]
  single_nat_gateway = true
  cluster_name       = "platform-dev"
}
```

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `name` | Name prefix for all resources | `string` | required |
| `cidr_block` | VPC CIDR | `string` | required |
| `azs` | Availability zones (2+) | `list(string)` | required |
| `single_nat_gateway` | One shared NAT instead of one per AZ | `bool` | `false` |
| `cluster_name` | Adds EKS subnet discovery tags | `string` | `null` |
| `flow_log_retention_days` | Flow log retention | `number` | `30` |
| `tags` | Common tags | `map(string)` | `{}` |

## Outputs

`vpc_id`, `vpc_cidr_block`, `public_subnet_ids`, `private_subnet_ids`, `database_subnet_ids`, `nat_public_ips`
