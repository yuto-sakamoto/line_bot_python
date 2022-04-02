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
variable "aws_profile" {}
#default_tags
locals {
  tags = {
    project     = "line_bot_python"
    environment = terraform.workspace
    terraform   = true
  }
}
# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# IAM
## policy
resource "aws_iam_policy" "dynamodb_put_policy" {
  name        = "dynamodb_put_policy"
  path        = "/"
  description = "DynamoDB put policy"
  tags        = local.tags
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:CreateTable",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

## user
resource "aws_iam_user" "dynamodb_user" {
  name = "dynamodb_user"
  tags = local.tags

}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.dynamodb_user.name
  policy_arn = aws_iam_policy.dynamodb_put_policy.arn
}
