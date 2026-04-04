# Usage Guide: From Repo Creation to Infrastructure Setup

This guide provides step-by-step instructions for initializing the repository and deploying the infrastructure using the provided Terraform modules and GitHub Actions.

## 1. Initial Repository Setup
1.  **Create a New GitHub Repository**: Create a private or public repository on GitHub.
2.  **Clone the Template**:
    ```bash
    git clone <your-repo-url>
    cd <repo-name>
    ```
3.  **Clean up previous state** (if any): Ensure no `.terraform` directories or `terraform.tfstate` files exist locally.

---

## 2. AWS Prerequisites (OIDC Provider)
To allow GitHub Actions to securely access AWS without long-lived credentials, you must set up an IAM OIDC Provider.

1.  **Create OIDC Provider**:
    -   Go to **IAM** -> **Identity Providers**.
    -   Add **OpenID Connect**.
    -   Provider URL: `https://token.actions.githubusercontent.com`
    -   Audience: `sts.amazonaws.com`
2.  **Create an IAM Role for GitHub**:
    -   Create a role with a **Custom Trust Policy** that allows `sts:AssumeRoleWithWebIdentity` from your specific GitHub repository.
    -   **Note the Role ARN**.
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Federated": "https://token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:*"
                }
            }
            }
        ]
    }
    ```
    - Attach necessary permissions (e.g., `AdministratorAccess` for the cluster setup).
    - Or Specific Permissions:
    ```json
    [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                ....
                ....
                ....
                ....
                ....
                ....
                ....
                ....
                ....
            ],
            "Resource": "*"
        }
    ]
    ```

---

## 📋 Prerequisites
- **AWS CLI** configured with administrator access.
- **Terraform** (v1.5+) installed locally.
- **GitHub Repository** with Actions enabled.

---

## 🛠️ Step 1: Bootstrap Remote State
Since Terraform needs a place to store its state *before* it can manage resources, we manually provision the S3 bucket and DynamoDB lock table.

1.  Navigate to the backend directory:
    ```bash
    cd infra/remote-state-backend/
    ```
2.  Run the bootstrap script:
    ```bash
    ./run.sh --action <ACTION> --profile <PROFILE> --env <ENV_NAME> --region <REGION> --bucket <BUCKET_NAME>
    ```
    *This script creates the S3 bucket and DynamoDB table (if they don't exist) and then runs `terraform apply` to manage them.*

---

## 🔐 Step 2: Configure GitHub Secrets
Your CI/CD pipelines need credentials and configuration values to run. Add the following to your GitHub Repository **Settings > Secrets and variables > Actions**:

### Environment Context
Create an environment in GitHub and add the following secrets and variables to it:

### Secrets
| Name | Description |
| :--- | :--- |
|`ACCOUNT_ID` | The AWS account ID. |
| `OIDC_INFRA_ROLE` | ARN of the IAM role for GitHub OIDC. |
| `REMOTE_STATE_BUCKET_NAME` | The name of the S3 bucket created in Step 1. |
| `DYNAMODB_TABLE_NAME_FOR_REMOTE_STATE_LOCKING` | The name of the DynamoDB table (e.g., `zaki-terraform-remote-state-lock-table`). |
### Variables
| Name | Description |
| :--- | :--- |
| `REGION` | Your target AWS region (e.g., `us-east-2`). |
| `ENV_NAME` | The environment name (e.g., `dev`). |

---

## 🚀 Step 3: Trigger Infrastructure Deployment
Now that the backend and secrets are ready, you can deploy your modules.

1.  **Add your module** to `infra/setup-order.txt` (e.g., add `vpc`).
2.  **Commit and Push** your changes to the `main` branch.
3.  GitHub Actions will automatically pick up the change and run:
    - **Infra Plan**: Triggered on Pull Requests:
    ```bash
    git branch <branch-name>
    git checkout <branch-name>
    # add your module to infra/setup-order.txt
    # create your module in infra/modules/<module-name>/main.tf
    git add .
    git commit -m "Add <module-name> module"
    git push -u origin <branch-name>
    # create a pull request
    # wait for the pull request to be approved and merged
    - **Infra Apply**: Triggered on push to `main`, directly or via merge (PR).
    ```
    git checkout main
    git pull origin main
    # add your module to infra/setup-order.txt
    # create your module in infra/modules/<module-name>/main.tf
    git add .
    git commit -m "Add <module-name> module"
    git push -u origin main
    
    
    ###################### create a pull request
    ###################### wait for the pull request to be approved and merged
    

---

## ✅ Step 4: Verify
Check the **Actions** tab in GitHub to ensure the jobs complete successfully. You can verify the resources in the AWS Console.
