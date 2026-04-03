# Project Analysis: EKS Infrastructure & CI/CD

This project implements an automated infrastructure setup for an AWS EKS cluster, currently focusing on the foundational remote state management.

## 🏗️ Infrastructure Architecture:

### 1. Remote State Backend (`infra/remote-state-backend`)
The core of the infrastructure is the Terraform remote state management, which ensures state consistency and locking across multiple environments/users.
- **Resources**:
    - **S3 Bucket**: Stores the `terraform.tfstate` file. Includes versioning and public access blocks for security.
    - **DynamoDB Table**: Provides state locking via a `LockID` attribute to prevent concurrent modifications.
- **Helper Scripts**:
    - [run.sh](../infra/remote-state-backend/run.sh): Automates S3 bucket creation and Terraform initialization. Supports flags: `--account`, `--region`, `--bucket`.
    - [delete.sh](../infra/remote-state-backend/delete.sh): Handles teardown of the state infrastructure. Supports flags: `--account`, `--region`, `--bucket`, `--env`, `--force`.

### 2. VPC Network Infrastructure (`infra/vpc`)
The network layer is built using the standard AWS VPC module, optimized for an EKS cluster deployment.
- **CIDR**: `10.11.0.0/16` in `us-east-2`.
- **Subnet Layout**:
    - **Public Subnets**: 2 subnets for Load Balancers and NAT Gateways.
    - **Private Subnets**: 4 subnets across 2 AZs for EKS worker nodes and internal services.
- **EKS Readiness**: Subnets are tagged for AWS Load Balancer Controller and Karpenter discovery.

### 3. Deployment Orchestration
- **[setup-order.txt](../infra/setup-order.txt)**: Defines the sequential order for applying infrastructure modules. It now contains:
    1. `remote-state-backend`
    2. `vpc`
- **[cleanup.sh](../infra/scripts/cleanup.sh)**: A critical utility that cleans up EKS-internal resources (LoadBalancers, PVCs, etc.) before running `terraform destroy`. This prevents "orphaned" resources that could block the deletion of the VPC or EKS cluster.

---

## 🚀 CI/CD Pipelines (GitHub Actions)

The project uses three main workflows located in [.github/workflows](../.github/workflows):

| Workflow | Trigger | Action | Key Features |
| :--- | :--- | :--- | :--- |
| **Infra Plan (CI)** | Pull Request to `main` | `terraform plan` | Detects changed directories; follows `setup-order.txt`. |
| **Infra Apply (CD)** | Push to `main` | `terraform apply` | Automates deployment of changes; follows `setup-order.txt`. |
| **Infra Destroy** | Manual (`workflow_dispatch`) | `terraform destroy` | Runs `cleanup.sh` first; destroys in reverse `setup-order.txt`. |

---

## 🛠️ Observations & Recommendations

1.  **Modular Design**: The use of `setup-order.txt` allows for easy expansion as more infrastructure components (VPC, EKS, RDS, etc.) are added.
2.  **State Security**: The S3 bucket policy enforces encrypted transport (`SecureTransport`) and server-side encryption (`AES256`).
3.  **Cleanup Robustness**: The inclusion of a dedicated EKS cleanup script is a best practice for avoiding leaked cloud resources during teardown.
4.  **Next Steps**: Implementation of the VPC and EKS cluster modules would be the logical progression for this project.
