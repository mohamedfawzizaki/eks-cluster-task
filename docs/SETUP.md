# 🚀 Step-by-Step Setup Guide

Follow these steps to deploy the infrastructure foundation from scratch.

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
    ./run.sh --action apply --env dev
    ```
    *This script creates the S3 bucket and DynamoDB table (if they don't exist) and then runs `terraform apply` to manage them.*

---

## 🔐 Step 2: Configure GitHub Secrets
Your CI/CD pipelines need credentials and configuration values to run. Add the following to your GitHub Repository **Settings > Secrets and variables > Actions**:

### Secrets
| Name | Description |
| :--- | :--- |
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
    - **Infra Plan**: Triggered on Pull Requests.
    - **Infra Apply**: Triggered on push to `main`.

---

## ✅ Step 4: Verify
Check the **Actions** tab in GitHub to ensure the jobs complete successfully. You can verify the resources in the AWS Console.
