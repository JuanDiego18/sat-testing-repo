resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "${var.prefix}-network"
  security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root_storage_bucket.bucket
  storage_configuration_name = "${var.prefix}-root-storage"
}

resource "databricks_mws_credentials" "this" {
  #account_id       = var.databricks_account_id
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${var.prefix}-root-storage-credentials"
  depends_on       = [time_sleep.wait]
}

## Adding 20 second timer to avoid Failed credential validation check
resource "time_sleep" "wait" {
  create_duration = "20s"
  depends_on = [
    aws_iam_role_policy.this
  ]
}

resource "databricks_mws_workspaces" "this" {
  account_id      = var.databricks_account_id
  aws_region      = var.region
  workspace_name  = "${var.prefix}-ws"
  deployment_name = "${var.prefix}-ws"

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id

  token {
    comment          = "SAT Workspace Token"
    lifetime_seconds = 172800
  }

  depends_on = [time_sleep.wait]
}


