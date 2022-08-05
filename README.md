# quickstart-sidecar-aws-ecs

## Deploy a single container sidecar on AWS ECS

This guide explains how to deploy a single container sidecar on AWS using 
the ECS service. 

By following the steps of this guide, you will deploy a sidecar container using 
a Fargate instance into an ECS cluster. You'll be able to configure the sidecar 
for specific data repositories and control de infrastructure in a way that best 
suits your company's needs.

In case you want to deploy a sidecar using AWS EC2 instead, please see
the [Cyral sidecar module for AWS EC2](https://github.com/cyralinc/terraform-cyral-sidecar-aws).

## Configure required providers
Set the required provider versions:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
    cyral = {
      source  = "cyralinc/cyral"
      version = ">= 2.7.0"
    }
  }
}
```
Configure the providers:
```terraform
provider "aws" {
  region = local.aws.region
}

provider "cyral" {
  # Follow the instructions in the Cyral Terraform Provider 
  # page to set up the credentials:
  # https://registry.terraform.io/providers/cyralinc/cyral/latest/docs
  client_id     = ""
  client_secret = ""
  control_plane = "${local.control_plane}:8000"
}
```

## Create a single container sidecar
You can register a single container sidecar and it's credentials 
in the Cyral control plane by using the following resources:
```terraform
resource "cyral_sidecar" "sidecar_ecs" {
  name              = "sidecar-ecs"
  deployment_method = "singleContainer"
}

resource "cyral_sidecar_credentials" "sidecar_credentials" {
  sidecar_id = cyral_sidecar.sidecar_ecs.id
}
```

## Define the sidecar parameters
Define the parameters that are going to be used to configure the sidecar.
```terraform
locals {
  # The address of the Cyral control plane. 
  # E.g.: "<tenant>.cyral.com"
  control_plane = ""
  sidecar = {
    # The sidecar identifier
    id = cyral_sidecar.sidecar_ecs.id
    # The version of the sidecar
    version = "v2.34.0"
    # Prefix used for names of created resources in AWS 
    # associated to the sidecar. Maximum length is 24 characters.
    name_prefix = "cyral-${substr(lower(cyral_sidecar.sidecar_ecs.id), -6, -1)}"
    # List of all repository types that will be supported by the
    # sidecar.
    repositories_supported = [
      "denodo", "dremio", "dynamodb", "mongodb", "mysql", 
      "oracle", "postgresql", "redshift", "rest", "snowflake",
      "sqlserver", "s3"
    ]
    # List of ports allowed to connect to the sidecar.'
    ports = [
        80, 443, 453, 1433, 1521, 3306, 3307, 5432, 5439, 9996, 
        9999, 27017, 27018, 27019, 31010
    ]
  }
}
```

## Define the ECS parameters
Define the parameters that going to be used to configure the ECS resources.
```terraform
locals {
  ecs = {
    # The name of an existent ECS cluster. In case you want to 
    # create a new cluster set this parameter as an empty string.
    cluster_name = "some-existing-ecs-cluster"
    # The CPU units used by the ECS service and task.
    cpu = 2048
    # The amount of memory used by the ECS service and task.
    memory = 4096
    # The sidecar ports that going to be mapped to the service.
    # The ports are splitted into a chunk of 5 due to ECS quota 
    # limitation of 5 target groups per service.
    service_ports = chunklist(local.sidecar.ports, 5)
    # The number of instances of the sidecar task definition
    # to place and keep running.
    service_desired_count = 1

    # The container registry where the sidecar image is stored.
    container_registry = "gcr.io/cyralinc"
    # The name of the sidecar container.
    container_name = "${local.sidecar.name_prefix}-sidecar-container"
    # A mapping of the sidecar container ports.
    container_ports_mappings = [for p in local.sidecar.ports : {
      "protocol" : "tcp"
      "containerPort" : p,
      "hostPort" : p,
    }]
  }
}
```

## Define the AWS parameters
Define the parameters of the AWS resources that are going to be used
to configure the sidecar infraestructure.
```terraform
locals {
  aws = {
    # The AWS region that the resources are going to be created.
    region = "us-east-1"
    # The ARN of the IAM role of the ECS task execution role.
    execution_iam_role_arn = ""
    # The ARN of the IAM role of the sidecar ECS container task,
    # This is the role used by the sidecar to make calls to other
    # AWS services.
    sidecar_iam_role_arn = ""
    # The ID of the sidecar security group.
    sidecar_security_group_ids = [""]
    # The ID of the sidecar subnets.
    sidecar_subnet_ids = [""]
    # The ARN of the secret where the registry credentials 
    # are stored. This is going to be used to pull the
    # sidecar image from the registry.
    registry_credentials_secret_arn = ""
    # The ARN of the SSM parameter where the sidecar
    # client ID is stored.
    sidecar_client_id_ssm_parameter_arn = ""
    # The ARN of the SSM parameter where the sidecar
    # client secret is stored.
    sidecar_client_secret_ssm_parameter_arn = ""
  }
}
```

## Configure the ECS resources
Create and configure the resources that will deploy
the sidecar container into the AWS ECS.
```terraform
# If the cluster_name is set, it will retrieve the existent
# cluster and use it to deploy the sidecar.
data "aws_ecs_cluster" "existent_cluster" {
  count        = local.ecs.cluster_name != "" ? 1 : 0
  cluster_name = local.ecs.cluster_name
}

# If the cluster_name is empty, it will create a new ECS
# cluster and use it to deploy the sidecar.
resource "aws_ecs_cluster" "sidecar_cluster" {
  count = local.ecs.cluster_name == "" ? 1 : 0
  name  = "${local.sidecar.name_prefix}-sidecar-cluster"
}

# Define the cluster capacity configuration for the new cluster.
resource "aws_ecs_cluster_capacity_providers" "sidecar_capacity_provider" {
  count              = local.ecs.cluster_name == "" ? 1 : 0
  cluster_name       = aws_ecs_cluster.sidecar_cluster[0].name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Define the task definition for the sidecar container.
# See the next section to configure the container definitions.
resource "aws_ecs_task_definition" "sidecar_task_definition" {
  family                   = "${local.sidecar.name_prefix}-sidecar-task"
  execution_role_arn       = local.aws.execution_iam_role_arn
  task_role_arn            = local.aws.sidecar_iam_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.ecs.cpu
  memory                   = local.ecs.memory
  container_definitions    = jsonencode(local.container_definition)  
}

# Define the ECS service that will run the sidecar container task.
# It will create one service per each 5 sidecar ports, due
# to ECS quota limitation of 5 target groups per service.
resource "aws_ecs_service" "sidecar_service" {
  count           = length(local.ecs.service_ports)
  name            = "${local.sidecar.name_prefix}-sidecar-service-${count.index}"
  cluster         = local.ecs.cluster_name == "" ? aws_ecs_cluster.sidecar_cluster[0].arn : data.aws_ecs_cluster.existent_cluster[0].arn
  task_definition = aws_ecs_task_definition.sidecar_task_definition.arn
  desired_count   = local.ecs.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.aws.sidecar_subnet_ids
    security_groups = local.aws.sidecar_security_group_ids
    assign_public_ip = true
  }
  # For each service port, a load balancer target group
  # will be mapped to the respective sidecar container
  # port.
  dynamic "load_balancer" {
    for_each = local.ecs.service_ports[count.index]
    content {
      target_group_arn = aws_lb_target_group.sidecar_lb_target_groups[(count.index * 5) + load_balancer.key].arn
      container_name   = local.ecs.container_name
      container_port   = load_balancer.value
    }
  }
}

```

### Container Definition Configuration
This section shows how to configure the sidecar container. It consists
of a list of valid task container definition parameters. For a detailed description
of what parameters are available, see the [Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html) in the
official AWS Developer Guide.
```terraform
locals {
  container_definition = [
    {
      # The sidecar container name
      name      = local.ecs.container_name
      # The image for a specific sidecar version, thats
      # stored in the container registry.
      image     = "${local.ecs.container_registry}/cyral-sidecar:${local.sidecar.version}"
      # The ARN of the AWS Secret Manager that stores
      # the registry credentials. For more details about
      # the format of the secret, see the AWS documentation
      # for Private registry authentication for tasks:
      # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html
      repositoryCredentials = (
        {
          credentialsParameter = local.aws.registry_credentials_secret_arn
        }
      )
      cpu       = local.ecs.cpu
      memory    = local.ecs.memory
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
          valueFrom = local.aws.sidecar_client_id_ssm_parameter_arn
        },
        {
          name      = "CYRAL_SIDECAR_CLIENT_SECRET"
          valueFrom = local.aws.sidecar_client_secret_ssm_parameter_arn
        }
      ]
      # The sidecar environment variables thats going to be used
      # to configure the sidecar.
      environment = [
        {
          "name"  = "CYRAL_CONTROL_PLANE"
          "value" = local.control_plane
        },
        {
          "name"  = "CYRAL_SIDECAR_ID"
          "value" = local.sidecar.id
        },
        {
          "name"  = "CYRAL_REPOSITORIES_SUPPORTED"
          "value" = join(",", local.sidecar.repositories_supported)
        },
        {
          "name"  = "CYRAL_SIDECAR_VERSION"
          "value" = local.sidecar.version
        },
        # Define this variable in case you have a DNS configured
        # for the sidecar. Otherwise ommit this variable to use
        # the default load balancer DNS.
        { 
          "name"  = "CYRAL_SIDECAR_ENDPOINT"
          "value" = local.sidecar.endpoint
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
          "awslogs-region"        = "${local.aws.region}",
          "awslogs-stream-prefix" = "cyral-logs"
        }
      }
    },
  ]
}
```

## Configure the sidecar for MongoDB cluster
In case you're using a sidecar for a MongoDB cluster, it will be necessary
to add the following configuration to your sidecar container definition:
```terraform
locals {
  sidecar = {
    # ...
    mongodb_port_alloc_range_low  = 27017
    mongodb_port_alloc_range_high = 27019
    # ...
  }
}
```
```terraform
locals {
  container_definition = [
    {
      # ...
      environment = [
        # ...
        # Initial and Final values for MongoDB port allocation range. The consecutive ports in the
        # range `CYRAL_MONGODB_PORT_ALLOC_RANGE_LOW:CYRAL_MONGODB_PORT_ALLOC_RANGE_HIGH` will be used
        # for MongoDB cluster monitoring. All the ports in this range must be listed in the sidecar ports.
        {
          "name"  = "CYRAL_MONGODB_PORT_ALLOC_RANGE_LOW"
          "value" = tostring(local.sidecar.mongodb_port_alloc_range_low)
        },
        {
          "name"  = "CYRAL_MONGODB_PORT_ALLOC_RANGE_HIGH"
          "value" = tostring(local.sidecar.mongodb_port_alloc_range_high)
        },
        # ...
      ]
      # ...
    },
  ]
}
```
## Next steps
In this guide, we described how to deploy and configure a single container sidecar into the AWS ECS. 
To learn how to access a repository through the sidecar, see the documentation
on how to [Connect to a repository](https://cyral.com/docs/connect/repo-connect/#connect-to-a-data-repository-with-sso-credentials).