output "role_arn" {
  description = "ARN of the created IAM role"
  value       = module.main.role_arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = module.main.role_name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (will be empty for Jenkins as it uses SAML)"
  value       = module.main.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (will be empty for Jenkins as it uses SAML)"
  value       = module.main.oidc_provider_url
}

output "assume_role_policy" {
  description = "The SAML assume role policy JSON used for the Jenkins role"
  value       = data.aws_iam_policy_document.jenkins_saml_assume_role.json
}