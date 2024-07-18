output "security_group_id" {
  value       = aws_security_group.sidecar_sg.id
  description = "Sidecar security group id"
}
