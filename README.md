# Terraform Modules by JHFlemos

A collection of reusable Terraform modules designed to accelerate and standardize infrastructure provisioning.

This repository leverages **Terramate** to manage modules, environments, and multi-module orchestration efficiently.

## 🚀 Why Use These Modules

- Encapsulates best‑practice patterns in Terraform for AWS infrastructure (VPCs, ECS, ALB, RDS, etc.).  
- Enables consistent naming, tagging, and environment support (dev/test/prod) using module inputs.  
- Promotes DRY (Don’t Repeat Yourself) infrastructure code — define once, reuse many times.  
- Designed to play nicely with CI/CD workflows, module versioning, and documentation automation.
- **Terramate** for workspace management and multi-module orchestration.

## 📦 Module Overview

Each module lives under `application/` or `functions/`, and follows this structure:

```
terraform-modules/
├── applications/
│ ├── simple-api-app/
│ ├── simple-http-app/
│ ├── cloudwatch.tm
│ ├── codedeploy.tm
│ ├── data.tm
│ ├── ecr.tm
│ ├── ecs.tm
│ ├── iam.tm
│ ├── kms.tm
│ ├── load-balance.tm
│ ├── security-group.tm
│ └── variables.tm
├── functions/
│ └── vpc/
│ ├── main.tf
│ ├── outputs.tf
│ ├── variables.tf
│ └── README.md
```

### Applications Modules

These modules help you deploy and manage:

- ECS services (`simple-api-app`, `simple-http-app`)
- ALB (Application Load Balancers)
- CloudWatch monitoring and alarms
- CodeDeploy canary/rolling deployments
- ECR repositories for Docker images
- IAM roles and policies
- KMS keys for encryption
- Security groups and networking
- Shared variables in `variables.tm`

### Functions Modules

Reusable helper modules, e.g.:

- `vpc` — Create VPCs, public and private subnets, routing, and outputs.

## 🔧 Usage Example

```hcl
module "vpc" {
  source      = "./functions/vpc"
  name        = "myapp-vpc"
  environment = "prod"
  aws_region  = "eu-west-1"

  public_subnets = [
    { cidr_block = "10.0.1.0/24", availability_zone = "eu-west-1a" },
    { cidr_block = "10.0.2.0/24", availability_zone = "eu-west-1b" }
  ]

  private_subnets = [
    { cidr_block = "10.0.11.0/24", availability_zone = "eu-west-1a" },
    { cidr_block = "10.0.12.0/24", availability_zone = "eu-west-1b" }
  ]

  tags = {
    Project     = "myapp"
    Environment = "prod"
  }
}

module "simple-http-app" {
  source      = "./applications/simple-http-app"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  # other module inputs...
}
```
## Terramate Integration

Terramate is used to organize multiple Terraform modules into workspaces and execute batch commands across modules.

Helps run plans, applies, and tests in all environments consistently.

### Generating a New Application with Terramate

Terramate provides a `generate` command to scaffold new Terraform modules or applications in your workspace. This ensures consistent structure, metadata, and documentation.

#### Example Command

```bash
terramate create applications/my-new-app \
  --description "My new application module" \
  --tags "tag1" --tags "tag2"
```

# GitHub Actions Workflows

This repository uses GitHub Actions to enforce CI/CD best practices, validate Terraform code, and manage releases.

## 1️⃣ `v1-ci-checks-tf`

**Triggered:** On pull requests affecting the `applications/**` or `functions/**` directories.  
**PR events:** `opened`, `reopened`, `synchronize`, `labeled`, `unlabeled`.  

**Purpose:**  
- Run `pre-commit` checks for Terraform code and other configured linters.
- Enforce PR labeling standards (`semver`, `type`, `do-not-merge`).

**Jobs:**

### a) `pre-commit`
- For each folder (`applications`, `functions`), iterates through subdirectories and runs all `pre-commit` checks for changed files.
- Skips directories with no changes compared to `origin/main`.

### b) `label-required-semver`
- Ensures pull requests have a version label with prefix `release/` (e.g., `release/patch`, `release/minor`, `release/major`).

### c) `label-required-pr-type`
- Ensures PRs are labeled with one of: `bug`, `enhancement`, `documentation`, `security`.

### d) `label-do-not-merge`
- Ensures PRs do **not** have the `do-not-merge` label.

---

## 2️⃣ `v1-func-create-tag-and-release`

**Triggered:** On pull request `closed` event (after merge).  

**Purpose:**  
- Automate semantic versioning and GitHub release creation for merged PRs based on labels.

**Jobs:**

### a) `create-new-release`
- Steps:
  1. Checkout the repository.
  2. Detect release label using `actions-ecosystem/action-release-label`.
  3. Get the latest Git tag (`actions-ecosystem/action-get-latest-tag`).
  4. Bump semantic version according to label (`actions-ecosystem/action-bump-semver`).
  5. Push new tag (`actions-ecosystem/action-push-tag`).
  6. Create a GitHub release (`softprops/action-gh-release`) with the new tag and PR details.

**Labels supported for version bumping:**
- `release/patch`
- `release/minor`
- `release/major`

**Outcome:**  
- Automatic tagging and release creation for merged PRs, maintaining semantic versioning.
