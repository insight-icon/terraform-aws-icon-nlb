output "citizen_target_group_arns" {
  value = aws_lb_target_group.citizen.arn
}

output "sentry_target_group_arns" {
  value = aws_lb_target_group.sentries.arn
}
