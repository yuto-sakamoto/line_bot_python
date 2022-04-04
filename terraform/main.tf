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
variable "channel_secret" {}
variable "channel_access_token" {}
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

# terraform use user
data "aws_caller_identity" "current" {}
# IAM
## policy
### dynamodb用
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
### lambda用
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "Lambda policy"
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
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:ap-northeast-1:${data.aws_caller_identity.current.account_id}:table/UserScore"
      },
      {
        Action = [
          "dynamodb:GetItem",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:ap-northeast-1:${data.aws_caller_identity.current.account_id}:table/Score"
      },
      {
        Action = [
          "logs:CreateLogGroup",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/line_bot_python:*"
      },
    ]
  })
}

#role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.lambda_policy.arn]
  tags                = local.tags
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

# lambda
resource "aws_lambda_function" "line_bot_lambda" {
  filename      = "../main.py.zip"
  function_name = "line_bot_python"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.test"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("../main.py.zip")

  runtime = "python3.9"

  environment {
    variables = {
      CHANNEL_SECRET       = var.channel_secret
      CHANNEL_ACCESS_TOKEN = var.channel_access_token
    }
  }
}
