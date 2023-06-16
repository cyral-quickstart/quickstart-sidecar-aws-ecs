locals {
  container_definition = [
    {
      # The sidecar container name
      name      = local.ecs.container_name
      # The image for a specific sidecar version, thats
      # stored in the container registry.
      image     = "${var.container_registry}/cyral-sidecar:${var.sidecar_version}"
      # The ARN of the AWS Secret Manager that stores
      # the registry credentials. For more details about
      # the format of the secret, see the AWS documentation
      # for Private registry authentication for tasks:
      # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html
      repositoryCredentials = (
        {
          credentialsParameter = aws_secretsmanager_secret.container_registry_credentials.arn
        }
      )
      cpu       = var.ecs_cpu
      memory    = var.ecs_memory
      essential = true
      portMappings = local.ecs.container_ports_mappings
      ulimits = [
        {
          name      = "nofile"
          hardLimit = 1048576
          softLimit = 1048576
        }
      ]
      secrets = [
        {
          name      = "CYRAL_SIDECAR_CLIENT_ID"
          valueFrom = aws_ssm_parameter.sidecar_client_id.arn

        },
        {
          name      = "CYRAL_SIDECAR_CLIENT_SECRET"
          valueFrom = aws_ssm_parameter.sidecar_client_secret.arn
        }
      ]
      # The sidecar environment variables thats going to be used
      # to configure the sidecar.
      environment = [
        {
          "name"  = "CYRAL_CONTROL_PLANE"
          "value" = var.control_plane
        },
        {
          "name"  = "CYRAL_SIDECAR_ID"
          "value" = var.sidecar_id
        },
        {
          "name"  = "CYRAL_SIDECAR_VERSION"
          "value" = var.sidecar_version
        },
        { 
          "name"  = "CYRAL_SIDECAR_ENDPOINT"
          "value" = var.sidecar_dns_name
        },
      ]
      # Define the log configuration, where sidecar will ship
      # the container logs to. For more information, see the
      # AWS documentation for ECS Log Configuration:
      # https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
      logConfiguration = {
        logDriver     = "awslogs",
        options       = {
          "awslogs-create-group"  = "true",
          "awslogs-group"         = "/ecs/${local.ecs.container_name}/",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "cyral-logs"
        }
      }
    },
  ]
}