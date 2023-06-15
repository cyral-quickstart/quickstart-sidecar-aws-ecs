locals {
  sidecar = {
    # Prefix used for names of created resources in AWS 
    # associated to the sidecar. Maximum length is 24 characters.
    name_prefix = "cyral-${substr(lower(var.sidecar_id), -6, -1)}"
  }
}

variable "control_plane" {
  description = "The address of the Cyral Control Plane. E.g.: '<tenant>.app.cyral.com'"
  type        = string
}

variable "sidecar_id" {
  description = "The sidecar identifier provided by the Control Plane."
  type        = string
}

variable "sidecar_version" {
  description = "The version of the sidecar."
  type        = string
}

variable "client_id" {
  description = "Sidecar Client ID provided by the Control Plane"
  type        = string
}

variable "client_secret" {
  description = "Sidecar Client Secret provided by the Control Plane"
  type        = string
  sensitive   = true
}

variable "sidecar_ports" {
  description = "List of ports allowed to connect to the sidecar."
  type        = list(number)
}

variable "sidecar_dns_name" {
  description = "The fully qualified sidecar domain name. If there's no DNS for the sidecar, use the load balancer DNS instead."
  type        = string
}

