# ----
# Primary resources IDs and names
# ----

output "role_arn" {
  description = "ARN of the CI/CD IAM role"
  value       = var.enabled ? aws_iam_role.cicd[0].arn : ""
}

output "role_name" {
  description = "Name of the CI/CD IAM role"
  value       = var.enabled ? aws_iam_role.cicd[0].name : ""
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = local.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = "https://${local.selected_oidc_provider}"
}
