# AWS account, partition, and region data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
