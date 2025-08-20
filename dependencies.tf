# AWS account, partition, and region data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# Data source for existing OIDC provider when not creating or managing one
data "aws_iam_openid_connect_provider" "existing" {
  count = var.enabled && !local.should_manage_oidc && !local.should_create_oidc && local.selected_oidc_provider.oidc_supported ? 1 : 0

  # Use provided ARN if available, otherwise lookup by URL
  arn = var.oidc_provider_arn != "" ? var.oidc_provider_arn : null
  url = var.oidc_provider_arn == "" ? "https://${local.selected_oidc_provider.oidc_url}" : null
}
