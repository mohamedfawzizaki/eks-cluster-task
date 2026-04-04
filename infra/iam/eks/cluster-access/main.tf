# Use a Data Source for the existing OIDC provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "zaki_eks_cluster_admin_githubactions_oidc" {
  name = var.github_oidc_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_repo}:*"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_oidc_admin" {
  role       = aws_iam_role.zaki_eks_cluster_admin_githubactions_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Or more restrictive EKS admin policies
}

# Standard SSO roles (Passed through for central reference)
locals {
  admin_sso_role_arn = var.admin_sso_role_arn
  power_sso_role_arn = var.power_sso_role_arn
}
