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
# Security group for the sidecar task.
resource "aws_security_group" "sidecar_sg" {
  name        = "${local.sidecar.name_prefix}-sidecar-container-sg"
  description = "Allow inbound access to sidecar ports"

  vpc_id = var.vpc_id

  # Allow the healthcheck to work
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.monitoring_inbound_cidr
  }

  dynamic "ingress" {
    for_each = var.sidecar_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.db_inbound_cidr
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Setup load balancer for the sidecar task.
resource "aws_lb" "sidecar_nlb" {
  name                       = "sidecar-nlb"
  load_balancer_type         = "network"
  internal                   =  var.load_balancer_scheme == "internet-facing" ? false : true
  subnets                    = var.subnets
  enable_deletion_protection = false
  tags = {
    Name = "${local.sidecar.name_prefix}-sidecar-container-sg"
  }
}

resource "aws_lb_listener" "sidecar_listener" {
  for_each          = { for port in var.sidecar_ports : tostring(port) => port }
  load_balancer_arn = aws_lb.sidecar_nlb.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.sidecar_tg[each.key].arn
  }
}

resource "aws_lb_target_group" "sidecar_tg" {
  for_each = { for port in var.sidecar_ports : tostring(port) => port }

  name        = "sidecar-tg-${each.key}"
  port        = each.value
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    port     = 9000
    protocol = "HTTP"
    path     = "/health"
  }
}
# Define the task definition for the sidecar container.
# See the sidecar_container_definition.tf file to configure 
# the container definitions.
resource "aws_ecs_task_definition" "sidecar_task_definition" {
  family                   = "${local.sidecar.name_prefix}-sidecar-task"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
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
    subnets          = var.subnets
    security_groups  = [aws_security_group.sidecar_sg.id]
    assign_public_ip = true
  }
  # For each service port, a load balancer target group
  # will be mapped to the respective sidecar container
  # port.
  dynamic "load_balancer" {
      for_each = aws_lb_target_group.sidecar_tg
      content {
        target_group_arn = load_balancer.value.arn
        container_name   = local.ecs.container_name
        container_port   = load_balancer.value.port
      }
    }
}
