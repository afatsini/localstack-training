provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

# Step 1: Create the IAM Policy to allow S3 actions
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow S3 operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::bucket",  # Specify your bucket
          "arn:aws:s3:::bucket/*" # Specify your bucket objects
        ]
      }
    ]
  })
}

# Step 2: Create the IAM Role
resource "aws_iam_role" "s3_role" {
  name = "S3AssumableRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.s3_user.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Step 3: Attach the S3 Policy to the Role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Step 4: Create the IAM User
resource "aws_iam_user" "s3_user" {
  name = "s3-user"
}

# Step 5: Create a Policy for the User to Assume the Role
resource "aws_iam_policy" "assume_role_policy" {
  name        = "AssumeS3RolePolicy"
  description = "Policy to allow user to assume the S3 role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.s3_role.arn
      }
    ]
  })
}

# Step 6: Attach the Assume Role Policy to the User
resource "aws_iam_user_policy_attachment" "attach_assume_role_policy" {
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

# Optional: Output the IAM User Access Key
resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}
