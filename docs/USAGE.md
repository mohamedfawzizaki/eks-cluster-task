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
    -   Attach necessary permissions (e.g., `AdministratorAccess` for the cluster setup).
    -   **Note the Role ARN**.

---

## 3. GitHub Repository Secrets
Navigate to **Settings** -> **Secrets and variables** -> **Actions** in your GitHub repository and add the following secret:

- `OIDC_ROLE`: The ARN of the IAM role created in Step 2.

---

## 4. Initializing the Remote State Backend
The remote state backend MUST be initialized before any other infrastructure.

### Option A: Local Initialization (Recommended for First Run)
1.  **Configure Local AWS Credentials**: Ensure your local terminal is authenticated with AWS.
    - If using SSO, run: `aws configure sso`
    - **Crucial**: Set the environment variable for your profile: `export AWS_PROFILE=<your-profile-name>` (e.g., `test-eks`).
2.  **Run the [run.sh](../infra/remote-state-backend/run.sh) script**:
    ```bash
    chmod +x infra/remote-state-backend/run.sh
    ./infra/remote-state-backend/run.sh apply
    ```
   This will:
   - Create the S3 bucket (if it doesn't exist).
   - Initialize Terraform with the correct backend configuration.
   - Create the DynamoDB lock table.

### Option B: CI Initialization
1.  Commit and push the code to `main`.
2.  Ensure `infra/setup-order.txt` contains `remote-state-backend`.
3.  The **DEV Cluster - Terraform Apply** workflow will automatically run.

---

## 5. Adding New Infrastructure Modules
1.  **Create a New Module**: Add a new directory under `infra/` (e.g., `infra/vpc`).
2.  **Configure Backend**: Copy the `backend.tf` and `versions.tf` from `remote-state-backend` and adjust the `key` in `backend.tf`.
3.  **Update [setup-order.txt](../infra/setup-order.txt)**: Add the module name on a new line.
    ```text
    remote-state-backend
    vpc
    eks
    ```
4.  **Commit & Push**: The CI/CD pipelines will detect the changes and apply them in the order specified.

---

## 6. Destroying Infrastructure
To completely teardown the infrastructure:
1.  Go to **Actions** in your GitHub repository.
2.  Select the **DEV Cluster - Terraform Destroy** workflow.
3.  Click **Run workflow**. 
    - This will run the `cleanup.sh` script first to delete EKS-internal resources.
    - Then it will run `terraform destroy` in the reverse order of `setup-order.txt`.

> [!IMPORTANT]
> To delete the Remote State S3 bucket itself, you must manually run or uncomment the deletion block in [delete.sh](../infra/remote-state-backend/delete.sh).
