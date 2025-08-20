output "role_arn" {
  description = "ARN of the created IAM role"
  value       = module.main.role_arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = module.main.role_name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for Terraform Cloud"
  value       = module.main.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for Terraform Cloud"
  value       = module.main.oidc_provider_url
}