locals {
  # Environment type configuration maps
  environment_defaults = {
    None = {
      rpo_hours = null
      rto_hours = null
    }
    Ephemeral = {
      rpo_hours = null
      rto_hours = 48
    }
    Development = {
      rpo_hours = 24
      rto_hours = 48
    }
    Testing = {
      rpo_hours = 24
      rto_hours = 48
    }
    UAT = {
      rpo_hours = 12
      rto_hours = 24
    }
    Production = {
      rpo_hours = 1
      rto_hours = 4
    }
    MissionCritical = {
      rpo_hours = 0.083 # 5 minutes
      rto_hours = 1
    }
  }

  # Apply environment defaults when environment_type is not "None"
  effective_config = var.environment_type == "None" ? (
    local.environment_defaults.None
    ) : (
    local.environment_defaults[var.environment_type]
  )

  # AWS account, partition, and region info
  account_id         = data.aws_caller_identity.current.account_id
  partition          = data.aws_partition.current.partition
  region             = data.aws_region.current.region
  dns_suffix         = data.aws_partition.current.dns_suffix
  reverse_dns_prefix = data.aws_partition.current.reverse_dns_prefix

  # Common tags for all resources including module metadata
  common_tags = merge(var.tags, {
    ModuleName    = "kbrockhoff/cicdrole/aws"
    ModuleVersion = local.module_version
    ModuleEnvType = var.environment_type
  })
  # Data tags take precedence over common tags
  common_data_tags = merge(local.common_tags, var.data_tags)

  name_prefix = var.name_prefix

  # CI/CD Provider configuration map
  cicd_providers_map = {
    # https://token.actions.githubusercontent.com/.well-known/openid-configuration
    "github-actions" = {
      oidc_url       = "token.actions.githubusercontent.com"
      oidc_supported = true
      sub_value      = ["repo:${var.git_provider_org}/${var.git_repo}:*"]
    }

    # https://gitlab.com/.well-known/openid-configuration
    "gitlab-ci" = {
      oidc_url       = "gitlab.com"
      oidc_supported = true
      sub_value      = ["project_path:${var.git_provider_org}/${var.git_repo}:*"]
    }

    # Bitbucket uses OAuth 2.0, requires workspace ID
    "bitbucket-pipelines" = {
      oidc_url       = "api.bitbucket.org/2.0/workspaces/${local.cicd_provider_org}/pipelines-config/identity/oidc"
      oidc_supported = true
      sub_value      = ["${var.git_provider_org}/${var.git_repo}:*"]
    }

    # https://oidc.circleci.com/org/{org-id}/.well-known/openid-configuration
    "circleci" = {
      oidc_url       = "oidc.circleci.com/org/${local.cicd_provider_org}"
      oidc_supported = true
      sub_value      = ["org/${var.git_provider_org}/project/${var.git_repo}/*"]
    }

    # https://app.vstoken.visualstudio.com/{tenantId}/.well-known/openid-configuration
    "azure-devops" = {
      oidc_url       = "app.vstoken.visualstudio.com/${local.cicd_provider_org}"
      oidc_supported = true
      sub_value      = ["sc://${var.git_provider_org}/${var.git_repo}/*"]
    }

    # Jenkins acts as OIDC client, not provider
    "jenkins" = {
      oidc_url       = "jenkins.io"
      oidc_supported = false
      sub_value      = []
    }

    # Travis CI doesn't have documented OIDC provider support
    "travis-ci" = {
      oidc_url       = "oidc.travis-ci.com"
      oidc_supported = false
      sub_value      = []
    }

    # Buildkite has OIDC support, uses organization slug
    "buildkite" = {
      oidc_url       = "agent.buildkite.com/${local.cicd_provider_org}"
      oidc_supported = true
      sub_value      = ["organization:${var.git_provider_org}:pipeline:${var.git_repo}:*"]
    }

    # AWS CodeBuild uses IAM/STS, not an OIDC provider
    "codebuild" = {
      oidc_url       = "codebuild.amazonaws.com"
      oidc_supported = false
      sub_value      = []
    }

    # https://app.harness.io/.well-known/openid-configuration
    "harness" = {
      oidc_url       = "app.harness.io"
      oidc_supported = true
      sub_value      = ["${var.git_provider_org}/${var.git_repo}:*"]
    }

    # TeamCity integrates with external OIDC providers, not a provider itself
    "teamcity" = {
      oidc_url       = "teamcity.jetbrains.com"
      oidc_supported = false
      sub_value      = []
    }

    # Drone CI OIDC provider capabilities not documented
    "drone-ci" = {
      oidc_url       = "drone.io"
      oidc_supported = false
      sub_value      = []
    }
  }

  # Use cicd_provider_org if provided, otherwise fall back to git_provider_org
  cicd_provider_org = var.cicd_provider_org != "" ? var.cicd_provider_org : var.git_provider_org

  # Selected OIDC provider URL based on cicd_provider variable
  selected_oidc_provider = local.cicd_providers_map[var.cicd_provider].oidc_url

  # Check if the selected provider supports OIDC
  provider_supports_oidc = local.cicd_providers_map[var.cicd_provider].oidc_supported

  # Determine if we should create the OIDC provider
  should_create_oidc = var.enabled && var.create_oidc_provider && !var.manage_oidc_provider && local.provider_supports_oidc

  # Determine if we should manage (import) the OIDC provider
  should_manage_oidc = var.enabled && var.manage_oidc_provider && local.provider_supports_oidc

  # OIDC provider ARN - managed, created, or provided
  oidc_provider_arn = var.enabled ? (
    local.should_manage_oidc ? (
      aws_iam_openid_connect_provider.managed[0].arn
      ) : (
      local.should_create_oidc ? (
        aws_iam_openid_connect_provider.cicd[0].arn
      ) : var.oidc_provider_arn
    )
  ) : ""

}
