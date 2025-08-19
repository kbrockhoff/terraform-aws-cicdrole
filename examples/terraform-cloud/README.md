# Terraform Cloud Dynamic Provider Credentials Example

This example demonstrates how to set up AWS Dynamic Provider Credentials for Terraform Cloud using OIDC authentication.

## Overview

Terraform Cloud supports Dynamic Provider Credentials which allows workspaces to authenticate to AWS using OIDC without storing long-lived AWS credentials. This example creates:
- An IAM role that trusts Terraform Cloud's OIDC provider
- An OIDC identity provider for Terraform Cloud
- Appropriate trust policies for your organization and workspaces

## Key Features

- **OIDC Authentication**: Uses `app.terraform.io` OIDC provider
- **Organization Scoping**: Configurable for your specific Terraform Cloud organization
- **Workspace/Project Filtering**: Can be scoped to specific workspaces or environments
- **No S3 Backend**: S3 backend permissions are disabled (Terraform Cloud manages state)

## Configuration

The example includes the following key configuration:
- `cicd_provider = "terraform-cloud"` - Specifies Terraform Cloud as the CI/CD provider
- `cicd_provider_org` - Your Terraform Cloud organization name
- `s3_backend_config.enabled = false` - Disables S3 backend permissions

## Variables

- `terraform_organization` - Your Terraform Cloud organization name
- `git_provider_org` - Your Git provider organization (GitHub/GitLab)
- `git_repos` - List of repository/project names that will use this role
- `deployment_environment` - Optional environment filter (leave empty for all workspaces)

## Usage

1. Update `terraform.auto.tfvars` with your organization details:
   ```hcl
   terraform_organization = "my-tfc-org"
   git_provider_org      = "my-github-org"
   git_repos             = ["infrastructure", "applications"]
   deployment_environment = "production"  # or "" for all environments
   ```

2. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Configure your Terraform Cloud workspace to use the created role:
   - Go to your workspace settings
   - Navigate to "Environment Variables"
   - Set `TFC_AWS_PROVIDER_AUTH` to `true`
   - Set `TFC_AWS_RUN_ROLE_ARN` to the output `role_arn`

## OIDC Trust Policy

The created role will trust OIDC tokens with subject claims matching:
- `organization:{terraform_organization}:project:{git_repos}:workspace:{deployment_environment}:run_phase:*`

If `deployment_environment` is empty, it will match all workspaces:
- `organization:{terraform_organization}:project:{git_repos}:workspace:*:run_phase:*`

## Requirements

- Terraform Cloud organization
- AWS credentials with permissions to create IAM roles and OIDC providers
- Terraform >= 1.5

## References

- [Terraform Cloud Dynamic Provider Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [AWS Configuration for Terraform Cloud](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration)