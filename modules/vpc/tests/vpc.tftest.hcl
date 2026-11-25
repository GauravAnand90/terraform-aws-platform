# Native Terraform tests (terraform test, 1.7+). The AWS provider is mocked,
# so these run in CI in seconds with no credentials and no cost.

mock_provider "aws" {
  # Mocked data sources return random strings; IAM resources need valid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  name       = "test"
  cidr_block = "10.10.0.0/16"
  azs        = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

run "creates_three_tiers_per_az" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3 && length(aws_subnet.database) == 3
    error_message = "Expected one public, private and database subnet per AZ."
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.10.64.0/20"
    error_message = "Private subnets should start at 10.10.64.0/20 for a /16 VPC."
  }

  assert {
    condition     = aws_subnet.database[2].cidr_block == "10.10.160.0/20"
    error_message = "Database subnets should be carved from the upper range."
  }
}

run "prod_has_nat_per_az" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Without single_nat_gateway, there must be one NAT gateway per AZ."
  }
}

run "dev_shares_one_nat" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway should create exactly one NAT gateway."
  }
}

run "eks_discovery_tags" {
  command = plan

  variables {
    cluster_name = "platform-test"
  }

  assert {
    condition     = aws_subnet.private[0].tags["kubernetes.io/role/internal-elb"] == "1"
    error_message = "Private subnets need the internal-elb tag for the AWS Load Balancer Controller."
  }

  assert {
    condition     = aws_subnet.public[0].tags["kubernetes.io/cluster/platform-test"] == "shared"
    error_message = "Subnets need the cluster tag when cluster_name is set."
  }
}

run "private_route_per_az" {
  command = plan

  assert {
    condition     = length(aws_route_table.private) == 3 && length(aws_route.private_nat) == 3
    error_message = "Each AZ needs its own private route table so AZ failures stay isolated."
  }
}

run "rejects_single_az" {
  command = plan

  variables {
    azs = ["us-west-2a"]
  }

  expect_failures = [var.azs]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    cidr_block = "not-a-cidr"
  }

  expect_failures = [var.cidr_block]
}
