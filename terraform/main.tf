terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# 変数定義
variable "aws_region" {}
# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}
