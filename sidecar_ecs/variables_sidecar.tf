locals {
  sidecar = {
    # Prefix used for names of created resources in AWS 
    # associated to the sidecar. Maximum length is 24 characters.
    name_prefix = "cyral-${substr(lower(var.sidecar_id), -6, -1)}"
  }
}

variable "control_plane" {
  description = "The address of the Cyral control plane. E.g.: '<tenant>.cyral.com'"
  type = string
}

variable "sidecar_id" {
  description = "The sidecar identifier."
  type = string
}

variable "sidecar_version" {
  description = "The version of the sidecar."
  type = string
}

variable "repositories_supported" {
  description = "List of all repository types that will be supported by the sidecar (lower case only)."
  type = list(string)
  default = [
    "denodo", "dremio", "dynamodb", "mongodb", "mysql", 
    "oracle", "postgresql", "redshift", "rest", "snowflake",
    "sqlserver", "s3"
  ]
}

variable "sidecar_ports" {
  description = "List of ports allowed to connect to the sidecar."
  type = list(number)
}

variable "mongodb_port_alloc_range_low" {
  description = <<EOF
Initial value for MongoDB port allocation range. The consecutive ports in the
range `mongodb_port_alloc_range_low:mongodb_port_alloc_range_high` will be used
for mongodb cluster monitoring. All the ports in this range must be listed in
`sidecar_ports`.
EOF
  type        = number
  default = 27017
}

variable "mongodb_port_alloc_range_high" {
  description = <<EOF
Final value for MongoDB port allocation range. The consecutive ports in the
range `mongodb_port_alloc_range_low:mongodb_port_alloc_range_high` will be used
for mongodb cluster monitoring. All the ports in this range must be listed in
`sidecar_ports`.
EOF
  type        = number
  default = 27029
}

variable "sidecar_dns_name" {
  description = "The fully qualified sidecar domain name. If there's no DNS for the sidecar, use the load balancer DNS instead."
  type = string
}

