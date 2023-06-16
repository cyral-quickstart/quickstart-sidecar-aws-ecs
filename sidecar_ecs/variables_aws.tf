variable "sidecar_vpc_id" {
  description = "The VPC ID of the sidecar subnets."
  type        = string
}

variable "load_balancer_scheme" {
  description = "Network load balancer scheme ('internal' or 'internet-facing')"
  type        = string
  default     = "internal"
}

variable "monitoring_inbound_cidr" {
  description = "CIDR allowed to access the monitoring port"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}