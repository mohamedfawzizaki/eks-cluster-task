output "admin_sso_role_arn" {
  value = var.admin_sso_role_arn
}

output "power_sso_role_arn" {
  value = var.power_sso_role_arn
}

output "admin_oidc_role_arn" {
  value = aws_iam_role.zaki_eks_cluster_admin_githubactions_oidc.arn
}
