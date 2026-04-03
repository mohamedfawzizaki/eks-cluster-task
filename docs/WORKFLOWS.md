# GitHub Workflows Guide: Execution & Triggers

This guide explains how each workflow in [.github/workflows](../.github/workflows) is triggered and how to use it.

## 1. 🔍 DEV Cluster - Terraform Plan (`infra-plan-ci.yaml`)
This workflow is used for **Continuous Integration (CI)**. It validates your Terraform code and shows a preview of changes without applying them.

-   **Trigger**: Automatically runs when a **Pull Request** is opened, updated, or reopened against the `main` branch. It detects changes in `.tf` and `.tfvars` files.
-   **How to Run**:
    1.  Create a new feature branch: `git checkout -b feature/new-infra`.
    2.  Make changes to Terraform files in `infra/`.
    3.  Push the branch to GitHub: `git push origin feature/new-infra`.
    4.  Open a Pull Request to `main`.
    5.  Check the **Checks** tab or the PR conversation for the Terraform Plan output.

---

## 2. 🚀 DEV Cluster - Terraform Apply (`infra-apply-cd.yaml`)
This workflow is used for **Continuous Deployment (CD)**. It applies the approved changes to your AWS environment.

-   **Trigger**: Automatically runs when code is **Pushed** or **Merged** into the `main` branch, provided there are changes in the `infra/` directory.
-   **How to Run**:
    1.  Merge an approved Pull Request into `main`.
    2.  Alternatively, push directly to `main` (not recommended for production).
    3.  Monitor the **Actions** tab for progress. It will follow the order in `setup-order.txt`.

---

## 3. 💣 DEV Cluster - Terraform Destroy (`infra-destroy.yaml`)
This workflow is used to **Teardown** the infrastructure. It is destructive and has safeguards.

-   **Trigger**: Manual only (**workflow_dispatch**). Requires `production` environment approval if configured in GitHub.
-   **How to Run**:
    1.  Go to the **Actions** tab in your repository.
    2.  Select **DEV Cluster - Terraform Destroy** from the list on the left.
    3.  Click the **Run workflow** dropdown button on the right.
    4.  (Optional) Change the `cluster_name` if needed (defaults to `zaki-eks-task`).
    5.  Click **Run workflow**.

> [!NOTE]
> The Destroy workflow runs the [cleanup.sh](../infra/scripts/cleanup.sh) script before running `terraform destroy`. This ensures that LoadBalancers and other Kubernetes-created AWS resources are cleaned up first, preventing deletion errors.

---

## Summary of Active Triggers

| Workflow | Path Filter | Branch | Event | manual |
| :--- | :--- | :--- | :--- | :--- |
| **Plan** | `infra/**` | `main` | `pull_request` | ❌ |
| **Apply** | `infra/**` | `main` | `push` | ❌ |
| **Destroy**| Any | `main` | `workflow_dispatch` | ✅ |
