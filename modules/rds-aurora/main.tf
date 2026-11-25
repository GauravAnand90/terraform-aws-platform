locals {
  engine           = "aurora-postgresql"
  family           = "aurora-postgresql${split(".", var.engine_version)[0]}"
  serverless       = var.instance_class == "db.serverless"
  final_snapshotid = "${var.name}-final"
}

resource "aws_kms_key" "db" {
  description             = "Storage, Performance Insights and secret encryption for ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "db" {
  name          = "alias/rds/${var.name}"
  target_key_id = aws_kms_key.db.key_id
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-aurora"
  description = "Aurora PostgreSQL access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-aurora" })
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from ${each.value}"
}

# Production-minded defaults: force TLS, log slow queries and DDL.
resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name}-cluster"
  family = local.family

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # ms
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = var.tags
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.name
  engine             = local.engine
  engine_mode        = "provisioned"
  engine_version     = var.engine_version

  database_name                 = var.database_name
  master_username               = var.master_username
  manage_master_user_password   = true # password lives in Secrets Manager, rotated by RDS
  master_user_secret_kms_key_id = aws_kms_key.db.key_id

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  storage_encrypted = true
  kms_key_id        = aws_kms_key.db.arn

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "08:00-09:00"         # UTC, low-traffic for US Pacific
  preferred_maintenance_window = "sun:09:30-sun:10:30" # UTC
  copy_tags_to_snapshot        = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshotid

  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]

  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.serverless && var.serverless_v2_scaling != null ? [var.serverless_v2_scaling] : []
    content {
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
    }
  }

  tags = var.tags
}

# ---------- Enhanced Monitoring ----------

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.name}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_partition" "current" {}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.name}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = false

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.db.arn

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.monitoring.arn

  auto_minor_version_upgrade = true

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}
