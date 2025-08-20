enabled     = true
name_prefix = "bitbucket-example"
tags = {
  "Environment" = "Production"
  "Example"     = "bitbucket"
}
environment_type     = "None"
create_oidc_provider = true
manage_oidc_provider = false
oidc_provider_arn    = ""
cicd_provider_org    = "DBSDEVMAN"
git_provider_org     = "42F8D7B2-D81C-47B0-8DFB-04AB4C0A8B22"
git_repos = [
  "{6FC9644A-48B1-458A-9895-4938CEBC50EC}:*",
  "{E14489E0-78BF-44BD-8B9C-83B42F23D0A2}:*",
  "{56E46EA7-0733-4D07-8783-2409203886FB}:*",
]
deployment_environment = "production"
s3_backend_config = {
  enabled        = true
  bucket_arn     = "arn:aws:s3:::bkff-tfstate-123456789012"
  lock_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/bkff-tfstate-123456789012-lock"
}
