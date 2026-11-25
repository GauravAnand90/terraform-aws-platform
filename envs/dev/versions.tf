terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Bucket is passed at init so no account ID lives in code:
  #   terraform init -backend-config="bucket=$TF_STATE_BUCKET"
  # use_lockfile = native S3 locking (Terraform 1.10+); no DynamoDB table needed.
  backend "s3" {
    key          = "envs/dev/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
