variable "github_thumbprint" {
  description = "GitHub OIDC thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1" # Standard GitHub OIDC thumbprint
}

variable "admin_sso_role_arn" {
  description = "Existing Admin SSO role ARN"
  type        = string
}

variable "power_sso_role_arn" {
  description = "Existing PowerUser SSO role ARN"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g., user/repo)"
  type        = string
}

variable "github_oidc_role_name" {
  description = "Name of the IAM role for GitHub Actions OIDC"
  type        = string
}
