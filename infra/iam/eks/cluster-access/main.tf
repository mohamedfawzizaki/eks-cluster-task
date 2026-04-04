# IAM Role for GitHub Actions OIDC
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
}

resource "aws_iam_role" "github_oidc" {
  name = "githubactions_oidc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
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
  role       = aws_iam_role.github_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Or more restrictive EKS admin policies
}

# Standard SSO roles (Passed through for central reference)
locals {
  admin_sso_role_arn = var.admin_sso_role_arn
  power_sso_role_arn = var.power_sso_role_arn
}
