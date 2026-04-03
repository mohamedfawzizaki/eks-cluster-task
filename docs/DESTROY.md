# 🧨 Step-by-Step Destruction Guide

Follow these steps to safely tear down your entire infrastructure and stop AWS costs.

---

## 💣 Step 1: Destroy Infrastructure Modules
This uses the automated GitHub Actions workflow to destroy resources in the correct dependency order.

1.  Go to your **GitHub Repository** -> **Actions** tab.
2.  Select the **"DEV Cluster - Terraform Destroy"** workflow from the sidebar.
3.  Click the **Run workflow** ▾ button.
4.  Optionally enter the `cluster_name` (default is `zaki-eks-task`).
5.  Click **Run workflow**.

> [!IMPORTANT]
> This workflow reads `infra/setup-order.txt`, reverses it, and runs `terraform destroy` for every module. This ensures the cluster is deleted before the VPC.

---

## 🗑️ Step 2: Delete Remote State Backend
After all infrastructure modules are destroyed, you can delete the state bucket and lock table. **Only do this if you are finished with this environment!**

1.  Navigate to the backend directory:
    ```bash
    cd infra/remote-state-backend/
    ```
2.  Run the deletion script:
    ```bash
    ./delete.sh --env dev --force
    ```
    *This script empties the S3 bucket (including all versions), deletes the bucket, and tears down the DynamoDB table.*

---

## ⚠️ Safety Checklist
- [ ] **Infrastructure First**: Never delete the backend before running the GitHub Destroy workflow.
- [ ] **Manual Resources**: If you created any resources manually (outside of Terraform), delete them manually in the AWS Console.
- [ ] **Verify**: Check the AWS Billing console and EC2/VPC dashboards to ensure no "ghost" resources (like unattached EIPs or NAT Gateways) remain.
