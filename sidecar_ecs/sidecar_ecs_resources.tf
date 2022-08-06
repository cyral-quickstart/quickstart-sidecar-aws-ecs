# If the cluster_name is set, it will retrieve the existent
# cluster and use it to deploy the sidecar.
data "aws_ecs_cluster" "existent_cluster" {
  count        = var.ecs_cluster_name != "" ? 1 : 0
  cluster_name = var.ecs_cluster_name
}

# If the cluster_name is empty, it will create a new ECS
# cluster and use it to deploy the sidecar.
resource "aws_ecs_cluster" "sidecar_cluster" {
  count = var.ecs_cluster_name == "" ? 1 : 0
  name  = "${local.sidecar.name_prefix}-sidecar-cluster"
}

# Define the cluster capacity configuration for the new cluster.
resource "aws_ecs_cluster_capacity_providers" "sidecar_capacity_provider" {
  count              = var.ecs_cluster_name == "" ? 1 : 0
  cluster_name       = aws_ecs_cluster.sidecar_cluster[0].name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Define the task definition for the sidecar container.
# See the sidecar_container_definition.tf file to configure 
# the container definitions.
resource "aws_ecs_task_definition" "sidecar_task_definition" {
  family                   = "${local.sidecar.name_prefix}-sidecar-task"
  execution_role_arn       = var.execution_iam_role_arn
  task_role_arn            = var.sidecar_iam_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  container_definitions    = jsonencode(local.container_definition)  
}

# Define the ECS service that will run the sidecar container task.
# It will create one service per each 5 sidecar ports, due
# to ECS quota limitation of 5 target groups per service.
resource "aws_ecs_service" "sidecar_service" {
  count           = length(local.ecs.service_ports)
  name            = "${local.sidecar.name_prefix}-sidecar-service-${count.index}"
  cluster         = var.ecs_cluster_name == "" ? aws_ecs_cluster.sidecar_cluster[0].arn : data.aws_ecs_cluster.existent_cluster[0].arn
  task_definition = aws_ecs_task_definition.sidecar_task_definition.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.sidecar_subnet_ids
    security_groups = var.sidecar_security_group_ids
    assign_public_ip = true
  }
  # For each service port, a load balancer target group
  # will be mapped to the respective sidecar container
  # port.
  dynamic "load_balancer" {
    for_each = local.ecs.service_ports[count.index]
    content {
      target_group_arn = var.sidecar_lb_target_group_arns[(count.index * 5) + load_balancer.key]
      container_name   = local.ecs.container_name
      container_port   = load_balancer.value
    }
  }
}
