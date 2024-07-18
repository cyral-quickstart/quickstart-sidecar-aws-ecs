output "ecs_cluster_arn" {
  value       = var.ecs_cluster_name == "" ? aws_ecs_cluster.sidecar_cluster[0].arn : null
  description = "ECS cluster ARN"
}

output "load_balancer_arn" {
  value       = aws_lb.sidecar_nlb.arn
  description = "Load balancer ARN"
}

output "load_balancer_dns" {
  value       = aws_lb.sidecar_nlb.dns_name
  description = "Sidecar load balancer DNS endpoint"
}

output "security_group_id" {
  value       = aws_security_group.sidecar_sg.id
  description = "Sidecar security group id"
}
