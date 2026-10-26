
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

data "archive_file" "backup" {
  type        = "zip"
  source_file = "${path.module}/../lambda/backup.py"
  output_path = "${path.module}/backup.zip"
}

resource "aws_iam_role" "backup" {
  name = "sprint-8-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "backup" {
  name = "sprint-8-backup-policy"
  role = aws_iam_role.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "backup" {
  function_name    = "sprint-8-backup"
  role             = aws_iam_role.backup.arn
  handler          = "backup.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.backup.output_path
  source_code_hash = data.archive_file.backup.output_base64sha256
  timeout          = 60
}

resource "aws_cloudwatch_event_rule" "daily" {
  name                = "sprint-8-daily-backup"
  description         = "Run the backup job every day at 02:00 UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "backup" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "sprint-8-backup"
  arn       = aws_lambda_function.backup.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
