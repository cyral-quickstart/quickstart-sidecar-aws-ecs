locals {
  ecs = {
    # The sidecar ports that going to be mapped to the service.
    # The ports are splitted into a chunk of 5 due to ECS quota 
    # limitation of 5 target groups per service.
    service_ports = chunklist(var.sidecar_ports, 5)
    # The name of the sidecar container.
    container_name = var.ecs_container_name == "" ? "${local.sidecar.name_prefix}-sidecar-container" : var.ecs_container_name
    # A mapping of the sidecar container ports.
    container_ports_mappings = [for p in var.sidecar_ports : {
      "protocol" : "tcp"
      "containerPort" : p,
      "hostPort" : p,
    }]
  }
}

variable "ecs_cluster_name" {
  description = "The name of an existent ECS cluster where the sidecar will be deployed. If this parameter is empty, a new cluster will be created with a default name with the format {name_prefix}-sidecar-cluster."
  type        = string
  default     = ""
}

variable "ecs_cpu" {
  description = "The CPU units used by the ECS service and task."
  type        = number
  default     = 2048
}

variable "ecs_memory" {
  description = "The amount of memory used by the ECS service and task."
  type        = number
  default     = 4096
}

variable "ecs_service_desired_count" {
  description = "The number of instances of the sidecar task definition to place and keep running."
  type        = number
  default     = 1
}

variable "container_registry" {
  description = "The container registry where the sidecar image is stored."
  default     = "public.ecr.aws/cyral"
  type        = string
}

variable "ecs_container_name" {
  description = "The name of the sidecar container. If not specified it will use a default name with the format {name_prefix}-sidecar-container."
  type        = string
  default     = ""
}
