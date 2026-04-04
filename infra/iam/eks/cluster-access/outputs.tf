output "admin_sso_role_arn" {
  value = var.admin_sso_role_arn
}

output "power_sso_role_arn" {
  value = var.power_sso_role_arn
}

output "admin_oidc_role_arn" {
  value = aws_iam_role.github_oidc.arn
}
