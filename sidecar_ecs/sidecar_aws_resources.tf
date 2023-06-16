locals {
  keyData = base64decode(var.container_registry_key)

  repoCreds = jsonencode({
    username = "_json_key"
    password = "${local.keyData}"
  })
  sidecarCredentials = jsonencode({
    clientId     = var.client_id
    clientSecret = var.client_secret
  })

}

# just use current aws region when region is required
data "aws_region" "current" {}

# Repo Creds - This assumes its the encoded value provided from the Cyral Control Plane
resource "aws_secretsmanager_secret" "repo_creds" {
  name                    = "cyral/repo-creds-${local.sidecar.name_prefix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "repo_creds_version" {
  secret_id     = aws_secretsmanager_secret.repo_creds.id
  secret_string = local.repoCreds
}

# Sidecar Client ID/Secret stores in SSM
resource "aws_ssm_parameter" "sidecar_client_id" {
  name  = "/cyral/${var.sidecar_id}/client_id"
  value = var.client_id
  type  = "String"
}

resource "aws_ssm_parameter" "sidecar_client_secret" {
  name  = "/cyral/${var.sidecar_id}/client_secret"
  value = var.client_secret
  type  = "SecureString"
}

# Role/Policy for ECS execution policy that gives the required access

resource "aws_iam_role" "sidecar_ecs_role" {
  name = "cyral_sidecar_ecs_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.sidecar_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow access to the resources needed to start the sidecar
resource "aws_iam_policy" "cyral_sidecar_ecs_policy" {
  name        = "cyral_sidecar_ecs_policy"
  description = "Custom policy for accessing secrets and SSM parameters for the sidecar"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:secretsmanager:*:*:secret:cyral/*",
          "arn:aws:ssm:*:*:parameter/cyral/*",
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  role       = aws_iam_role.sidecar_ecs_role.name
  policy_arn = aws_iam_policy.cyral_sidecar_ecs_policy.arn
}
