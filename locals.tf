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

}
