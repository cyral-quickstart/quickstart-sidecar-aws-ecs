variable "enable_cross_zone_load_balancing" {
  description = "Enable cross zone load balancing"
  type        = bool
  default     = true
}

variable "load_balancer_scheme" {
  description = "Network load balancer scheme ('internal' or 'internet-facing')"
  type        = string
  default     = "internal"
}

variable "load_balancer_security_groups" {
  description = <<EOF
List of the IDs of the additional security groups that will be attached to the load balancer.
EOF
  type        = list(string)
  default     = []
}

variable "load_balancer_subnets" {
  description = <<EOF
Subnets to add load balancer to. If not provided, the load balancer will assume the subnets
specified in the `subnets` parameter.
EOF
  type        = list(string)
  default     = []
}

variable "monitoring_inbound_cidr" {
  description = "CIDR allowed to access the monitoring port"
  type        = list(string)
  default     = []
}

variable "subnets" {
  type = list(string)
  description = "The list of subnets the ECS service and loadbalancer will use. If no value is provided it will attempt to us all subnets on the VPC"
}

variable "vpc_id" {
  description = "The VPC ID of the sidecar subnets."
  type        = string
}
