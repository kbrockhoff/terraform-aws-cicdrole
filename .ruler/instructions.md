# AWS Role for CI/CD Pipeline Terraform Module Guide for AI Agents

Terraform module which an IAM Role on AWS which trusts CI/CD system OIDC provider.

## Components

### IAM Role
- Trusts CI/CD system OIDC provider from a select list
- Has permissions to use Terraform S3 backend

