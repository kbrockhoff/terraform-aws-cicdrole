locals {

  # AWS account, partition, and region info
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  dns_suffix = data.aws_partition.current.dns_suffix

  # Common tags for all resources including module metadata
  common_tags = merge(var.tags, {
    ModuleName    = "kbrockhoff/cicdrole/aws"
    ModuleVersion = local.module_version
    ModuleEnvType = var.environment_type
  })

  name_prefix = "${var.name_prefix}-${var.cicd_provider}"

  # GitHub Actions subject claims
  # Legacy:    repo:<org>/<repo>:<context>
  # Immutable: repo:<org>@<org_id>/<repo>@<repo_id>:<context>
  # Immutable IDs prevent a recycled org/repo name from matching this trust policy.
  # git_repos entries may carry an "@<repo_id>" suffix; legacy patterns strip it,
  # immutable patterns without one match any repo ID under the pinned org ID.
  github_sub_context = var.deployment_environment != "" ? "environment:${var.deployment_environment}" : "*"
  github_legacy_subs = [
    for repo in var.git_repos : "repo:${var.git_provider_org}/${split("@", repo)[0]}:${local.github_sub_context}"
  ]
  github_immutable_subs = [
    for repo in var.git_repos :
    "repo:${var.git_provider_org}@${var.git_provider_org_id}/${strcontains(repo, "@") ? repo : "${repo}@*"}:${local.github_sub_context}"
  ]
  github_sub_values = concat(
    var.github_subject_format != "immutable" ? local.github_legacy_subs : [],
    var.github_subject_format != "legacy" ? local.github_immutable_subs : [],
  )

  # CI/CD Provider configuration map
  cicd_providers_map = {
    # https://token.actions.githubusercontent.com/.well-known/openid-configuration
    "github-actions" = {
      oidc_url       = "token.actions.githubusercontent.com"
      oidc_supported = true
      aud_value      = "sts.amazonaws.com"
      sub_values     = local.github_sub_values
    }

    # https://gitlab.com/.well-known/openid-configuration
    "gitlab-ci" = {
      oidc_url       = "gitlab.com"
      oidc_supported = true
      aud_value      = "https://gitlab.com"
      sub_values = flatten([
        for repo in var.git_repos : "project_path:${var.git_provider_org}/${repo}:*"
      ])
    }

    # Bitbucket uses OAuth 2.0, requires workspace ID
    "bitbucket-pipelines" = {
      oidc_url       = "api.bitbucket.org/2.0/workspaces/${local.cicd_provider_org}/pipelines-config/identity/oidc"
      oidc_supported = true
      aud_value      = "ari:cloud:bitbucket::workspace/${var.git_provider_org}"
      sub_values     = flatten(var.git_repos)
    }

    # https://oidc.circleci.com/org/{org-id}/.well-known/openid-configuration
    "circleci" = {
      oidc_url       = "oidc.circleci.com/org/${local.cicd_provider_org}"
      oidc_supported = true
      aud_value      = "sts.amazonaws.com"
      sub_values = flatten([
        for repo in var.git_repos : "org/${var.git_provider_org}/project/${repo}/*"
      ])
    }

    # https://vstoken.dev.azure.com/{tenantId}/.well-known/openid-configuration
    "azure-devops" = {
      oidc_url       = "vstoken.dev.azure.com/${local.cicd_provider_org}"
      oidc_supported = true
      aud_value      = "api://AzureADTokenExchange"
      sub_values = flatten([
        for repo in var.git_repos : "sc://${var.git_provider_org}/${repo}/*"
      ])
    }

    # Jenkins acts as OIDC client, not provider
    "jenkins" = {
      oidc_url       = "jenkins.io"
      oidc_supported = false
      aud_value      = ""
      sub_values     = []
    }

    # Travis CI doesn't have documented OIDC provider support
    "travis-ci" = {
      oidc_url       = "oidc.travis-ci.com"
      oidc_supported = false
      aud_value      = ""
      sub_values     = []
    }

    # https://agent.buildkite.com/.well-known/openid-configuration
    "buildkite" = {
      oidc_url       = "agent.buildkite.com"
      oidc_supported = true
      aud_value      = "sts.amazonaws.com"
      sub_values = flatten([
        for repo in var.git_repos : "organization:${var.cicd_provider_org}:pipeline:${repo}:*"
      ])
    }

    # AWS CodeBuild uses IAM/STS, not an OIDC provider
    "codebuild" = {
      oidc_url       = "codebuild.amazonaws.com"
      oidc_supported = false
      aud_value      = ""
      sub_values     = []
    }

    # https://app.harness.io/.well-known/openid-configuration
    "harness" = {
      oidc_url       = "app.harness.io/ng/api/oidc/account/${local.cicd_provider_org}"
      oidc_supported = true
      aud_value      = "sts.amazonaws.com"
      sub_values = flatten([
        for repo in var.git_repos : "account/${local.cicd_provider_org}:org/default:project/${repo}"
      ])
    }

    # TeamCity integrates with external OIDC providers, not a provider itself
    "teamcity" = {
      oidc_url       = "teamcity.jetbrains.com"
      oidc_supported = false
      aud_value      = ""
      sub_values     = []
    }

    # Drone CI OIDC provider capabilities not documented
    "drone-ci" = {
      oidc_url       = "drone.io"
      oidc_supported = false
      aud_value      = ""
      sub_values     = []
    }

    # https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration
    "terraform-cloud" = {
      oidc_url       = "app.terraform.io"
      oidc_supported = true
      aud_value      = "aws.workload.identity"
      sub_values = var.deployment_environment != "" ? flatten([
        for repo in var.git_repos : "organization:${local.cicd_provider_org}:project:${repo}:workspace:${var.deployment_environment}:run_phase:*"
        ]) : flatten([
        for repo in var.git_repos : "organization:${local.cicd_provider_org}:project:${repo}:workspace:*:run_phase:*"
      ])
    }

    # https://developer.hashicorp.com/terraform/enterprise/workspaces/dynamic-provider-credentials/aws-configuration
    "terraform-enterprise" = {
      oidc_url       = local.cicd_provider_org != "" ? local.cicd_provider_org : "terraform.example.com"
      oidc_supported = true
      aud_value      = "aws.workload.identity"
      sub_values = var.deployment_environment != "" ? flatten([
        for repo in var.git_repos : "organization:${local.cicd_provider_org}:project:${repo}:workspace:${var.deployment_environment}:run_phase:*"
        ]) : flatten([
        for repo in var.git_repos : "organization:${local.cicd_provider_org}:project:${repo}:workspace:*:run_phase:*"
      ])
    }

    # https://docs.scalr.com/en/latest/workspaces.html#dynamic-provider-credentials
    "scalr" = {
      oidc_url       = local.cicd_provider_org != "" ? "${local.cicd_provider_org}.scalr.io" : "example.scalr.io"
      oidc_supported = true
      aud_value      = "aws.workload.identity"
      sub_values = var.deployment_environment != "" ? flatten([
        for repo in var.git_repos : "scalr:account:${local.cicd_provider_org}:environment:${var.deployment_environment}:workspace:${repo}:run_phase:*"
        ]) : flatten([
        for repo in var.git_repos : "scalr:account:${local.cicd_provider_org}:environment:*:workspace:${repo}:run_phase:*"
      ])
    }

    # https://docs.spacelift.io/concepts/stack/dynamic-credentials/
    "spacelift" = {
      oidc_url       = local.cicd_provider_org != "" ? "${local.cicd_provider_org}.app.spacelift.io" : "example.app.spacelift.io"
      oidc_supported = true
      aud_value      = "spacelift"
      sub_values = flatten([
        for repo in var.git_repos : "space:${local.cicd_provider_org}:stack:${repo}:*"
      ])
    }
  }

  # Use cicd_provider_org if provided, otherwise fall back to git_provider_org
  cicd_provider_org = var.cicd_provider_org != "" ? var.cicd_provider_org : var.git_provider_org

  # Selected OIDC provider configuration based on cicd_provider variable
  selected_oidc_provider = local.cicd_providers_map[var.cicd_provider]

  # Determine if we should create the OIDC provider
  should_create_oidc = var.enabled && var.create_oidc_provider && !var.manage_oidc_provider && local.selected_oidc_provider.oidc_supported

  # Determine if we should manage (import) the OIDC provider
  should_manage_oidc = var.enabled && var.manage_oidc_provider && local.selected_oidc_provider.oidc_supported

  # OIDC provider ARN - managed, created, or use data source
  oidc_provider_arn = var.enabled ? (
    local.should_manage_oidc ? (
      aws_iam_openid_connect_provider.managed[0].arn
      ) : (
      local.should_create_oidc ? (
        aws_iam_openid_connect_provider.cicd[0].arn
        ) : (
        local.selected_oidc_provider.oidc_supported ? (
          data.aws_iam_openid_connect_provider.existing[0].arn
        ) : var.oidc_provider_arn
      )
    )
  ) : ""

}
