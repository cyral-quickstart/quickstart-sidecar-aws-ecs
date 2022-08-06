variable "aws_region" {
  description = "The AWS region that the resources are going to be created."
  type = string
}

variable "execution_iam_role_arn" {
  description = "The ARN of the IAM role of the ECS task execution role."
  type = string
}

variable "sidecar_iam_role_arn" {
  description = "The ARN of the IAM role of the sidecar ECS container task. This is the role used by the sidecar to make calls to other AWS services."
  type = string
}

variable "sidecar_security_group_ids" {
  description = "The ID of the sidecar security group."
  type = list(string)
}

variable "sidecar_subnet_ids" {
  description = "The ID of the sidecar subnets."
  type = list(string)
}

variable "registry_credentials_secret_arn" {
  description = "The ARN of the secret where the registry credentials are stored. This is going to be used to pull the sidecar image from the registry."
  type = string
}

variable "sidecar_client_id_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter where the sidecar client ID is stored."
  type = string
}

variable "sidecar_client_secret_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter where the sidecar client secret is stored."
  type = string
}

variable "sidecar_lb_target_group_arns" {
  description = "A list of the ARNs of the sidecar load balancer target groups. There must be one target group per sidecar port defined."
  type = list(string)
}
