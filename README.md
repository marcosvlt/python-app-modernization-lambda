# 🚀 Enacom Challenge - FIPE Data Processor

A serverless Modernized AWS solution that processes FIPE vehicle data using containerized Lambda functions triggered by S3 events. The system function processes FIPE CSV files and performs data cleaning operations:

Validates required fields (codigoFipe, marca, modelo, anoModelo, valor)
Removes duplicates based on unique combination of key fields
Corrects data errors:
Reformats data:




##  Architecture

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   S3 Input  │ ──────> │ Lambda (ECR) │ ──────> │  S3 Output   │
│   Bucket    │  Event  │   Function   │  JSON   │   Bucket     │
└─────────────┘         └──────┬───────┘         └──────────────┘
                               │
                               v
                        ┌──────────────┐
                        │  CloudWatch  │
                        │     Logs     │
                        └──────────────┘
```

### Components

- **Amazon S3**: Two buckets for input (CSV files) and output (JSON results)
- **AWS Lambda**: Container-based function (Python 3.11) that processes FIPE data
- **Amazon ECR**: Stores Docker images per environment (dev/stage/prod)
- **IAM**: Role-based access control with least privilege principles
- **CloudWatch Logs**: Centralized logging for monitoring and debugging
- **Terraform**: Infrastructure as Code for reproducible deployments
- **GitHub Actions**: Complete CI/CD pipeline with automated workflows

### Data Flow

1. CSV file uploaded to input S3 bucket
2. S3 event triggers Lambda function automatically
3. Lambda downloads CSV, processes data (calculates averages by year and brand)
4. Results saved as JSON to output S3 bucket
5. All operations logged to CloudWatch

---

## 💡 Why AWS Lambda (with Container)?

### Technical Justification

| Criteria        | AWS Lambda ✅                        | AWS Fargate                                      |
|-----------------|--------------------------------------|--------------------------------------------------|
| **Cost**        | Very low, charged per invocation     | More expensive (keeps tasks running)             |
| **Complexity**  | Simple, no cluster required          | Requires ECS Cluster + Service or Scheduled Task |
| **Workload**    | Short execution and batch jobs       | Better suited for long-running workloads         |
| **Scalability** | Automatic and instantaneous          | Automatic but slower                             |
| **Admin**       | Zero administration                  | Requires ECS/Fargate configuration               |

**Why Lambda is perfect for this use case:**

✅ The application is a **one-off batch job** → Lambda is ideal  
✅ Execution lasts only a **few seconds**  
✅ Can be packaged as a **container** without code changes  
✅ Lambda supports up to **15 minutes** → more than sufficient  
✅ **Near-zero cost** (pay only when triggered)  
✅ **Auto-scaling** built-in  
✅ **Container support** allows using custom dependencies

---

## Prerequisites

Before you begin, ensure you have:

- ✅ **AWS Account** with administrative permissions
- ✅ **AWS CLI** installed and configured
- ✅ **Terraform** >= 1.6.0
- ✅ **Git** and **GitHub CLI** (optional but recommended)
- ✅ **GitHub Account** with repository access

### AWS Setup - OIDC Authentication

1. **Create OIDC Provider in AWS IAM**

   Go to AWS Console → IAM → Identity Providers → Add Provider:

   **Provider URL:**
   ```
   https://token.actions.githubusercontent.com
   ```

   **Audience:**
   ```
   sts.amazonaws.com
   ```

2. **Create IAM Role for GitHub Actions**

   Create a role with this trust policy (replace `<ACCOUNT_ID>`, `<ORG>`, and `<REPO>`):

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:*"
           }
         }
       }
     ]
   }
   ```

3. **Attach Permissions** to the role:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonS3FullAccess`
   - `AWSLambdaFullAccess`
   - `IAMFullAccess`
   - Custom policy for DynamoDB (Terraform state locking)

4. **Configure GitHub Secret**

   Add this secret to your GitHub repository (Settings → Secrets → Actions):
   - **Name:** `ROLE_ARN`
   - **Value:** `arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>`

---

## Quick Start

### Option 1: Automated Deployment (Recommended)

The easiest way to deploy the entire infrastructure:

```bash
# 1. Clone the repository
git clone https://github.com/marcosvlt/Enacom-desafio.git
cd Enacom-desafio

# 2. Create and push environment branches
git checkout -b dev
git push -u origin dev

git checkout -b stage
git push -u origin stage

git checkout -b prod
git push -u origin prod

# 3. Go to GitHub Actions and run workflows in order:
#    a) 01 - Setup Terraform Backend (action: apply)
#    b) 02 - Build and Deploy ECR (action: create-and-build, environment: all)
#       OR run individually per environment (dev, stage, prod)
#    c) Deploy Infrasctructure (environment: dev, action: apply)

# 4. Test by uploading a CSV file
aws s3 cp sample-data.csv s3://<your-input-bucket>/
```

---

## 📖 Deployment Guide

### Step 1: Setup Terraform Backend

The backend stores Terraform state in S3 with DynamoDB for state locking.

**Via GitHub Actions:**

1. Go to **Actions** → **01 - Setup Terraform Backend**
2. Click **Run workflow**
3. Select:
   - `action`: **apply**
   - `aws_region`: **us-east-1** (or your preferred region)
4. Click **Run workflow**

**Manually (alternative):**

```bash
cd Terraform/backend
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

✅ **Result:** S3 bucket and DynamoDB table created for Terraform state management

---

### Step 2: Create ECR Repositories and Build Docker Images

Create Docker image repositories and build/push images in one unified workflow.

**Via GitHub Actions (Recommended - All Environments at Once):**

1. Go to **Actions** → **02 - Build and Deploy ECR**
2. Click **Run workflow**
3. Select:
   - `action`: **create-and-build** (creates ECR + builds & pushes images)
   - `environment`: **all** (deploys to dev, stage, and prod in parallel)
   - `aws_region`: **us-east-1**
4. Click **Run workflow**

✅ **Result:** All ECR repositories created + Docker images built and pushed with tags:
- `lambda-fipe-dev`, `lambda-fipe-stage`, `lambda-fipe-prod`
- `latest`
- Commit SHA (e.g., `abc123def456...`)

**Alternative - Individual Environment:**

Run the workflow 3 times with `environment` set to `dev`, `stage`, then `prod` individually.

**Alternative - Create ECR Only (No Docker Build):**

Use `action`: **create-only** to just create ECR repositories without building images.

**Alternative - Build Docker Only (ECR Must Exist):**

Use `action`: **build-only** to build and push images to existing ECR repositories.

**Manually via Terraform (Advanced):**

```bash
# For dev environment
cd Terraform/environments/dev/build
terraform init -var "repository_name=python-app-modernization-lambda"
terraform plan -out=tfplan -var "repository_name=python-app-modernization-lambda"
terraform apply tfplan

# Repeat for stage and prod
```

✅ **Result:** ECR repositories created:
- `python-app-modernization-lambda-dev`
- `python-app-modernization-lambda-stage`
- `python-app-modernization-lambda-prod`

---

### Step 3: Deploy Application (Docker + Infrastructure)

This is the **main deployment workflow** that:
1. Builds and pushes Docker image to ECR
2. Deploys Lambda function and S3 buckets via Terraform

**Via GitHub Actions (Recommended):**

1. Go to **Actions** → **Deploy Application**
2. Click **Run workflow**
3. Select:
   - `environment`: **dev** (start with dev)
   - `action`: **apply**
   - `skip_docker_build`: **false**
   - `aws_region`: **us-east-1**
4. Click **Run workflow**

**What happens:**
- ✅ Detects changes in Docker and Terraform
- ✅ Builds Docker image with build metadata
- ✅ Pushes to ECR with tags: `lambda-fipe-dev`, `latest`, and commit SHA
- ✅ Deploys Lambda function, S3 buckets, IAM roles
- ✅ Configures S3 event trigger
- ✅ Generates deployment summary

**Via Pull Request (Production Method):**

```bash
# Make changes to Docker or Terraform
vim Docker/src/lambda_function.py

git checkout -b feature/my-changes
git add .
git commit -m "feat: update lambda function"
git push origin feature/my-changes

# Create PR to dev
gh pr create --base dev --head feature/my-changes

# Review the automated plan in PR comments
# Merge PR → Automatic deployment to dev
```

✅ **Result:** Complete infrastructure deployed and ready to process CSV files

---

## 🔄 GitHub Workflows Explained

This repository includes **5 GitHub Actions workflows** that automate the entire deployment pipeline:

### 1. **01 - Setup Terraform Backend**

**Purpose:** Creates S3 bucket and DynamoDB table for Terraform state management

**When to use:** Run once at the beginning of the project

**Inputs:**
- `action`: `apply` | `destroy`
- `aws_region`: AWS region (default: `us-east-1`)

**Trigger:** Manual (`workflow_dispatch`)

---

### 2. **02 - Build and Deploy ECR** (Unified Workflow)

**Purpose:** Comprehensive workflow that manages ECR repositories AND Docker image building/pushing in a single, intelligent pipeline

**When to use:** 
- Automatically on PRs to environment branches (builds but doesn't push)
- Automatically on pushes to environment branches (builds and pushes)
- Manually when you need full control over ECR and Docker operations

**Triggers:**
- `pull_request` → Builds Docker image (no push) for testing
- `push` → Builds and pushes Docker image on branch commits
- `workflow_dispatch` → Manual execution with full control

**Inputs (Manual Dispatch):**
- `action`: 
  - `create-and-build` - Creates ECR repo + builds and pushes image (default)
  - `build-only` - Only builds and pushes image (repo must exist)
  - `create-only` - Only creates ECR repository
  - `destroy` - Destroys ECR repository
- `environment`: `dev` | `stage` | `prod` | `all`
- `aws_region`: AWS region (default: `us-east-1`)

**Output:** 
- ECR repository URL for each environment
- Docker image URIs with multiple tags
- Comprehensive deployment summary

#### 🎯 Key Features:

**1. Flexible Actions:**
- `create-and-build` - Complete setup: ECR + Docker build/push (default)
- `build-only` - Updates existing images (repo must exist)
- `create-only` - Infrastructure only (no Docker build)
- `destroy` - Clean removal of ECR repository

**2. Multi-Environment Support:**
- Target single environment: `dev`, `stage`, `prod`
- Target all environments at once with `all` option
- Uses matrix strategy for parallel execution
- Environment auto-detection from branch on PR/push events

**3. Intelligent Job Orchestration:**
- `determine-environments` - Figures out which environments to target based on trigger
- `create-ecr-repositories` - Creates ECR repos via Terraform (conditional)
- `build-and-push-images` - Builds and pushes Docker images with multiple tags (conditional)
- `summary` - Generates comprehensive deployment summary with all job results

**4. Safety Features:**
- ✅ Checks if ECR repository exists before attempting build
- ✅ Fail-fast disabled for matrix (continues even if one environment fails)
- ✅ Verifies repository creation before building images
- ✅ Uses conditional logic to skip jobs based on action
- ✅ PR safety: builds images but doesn't push (testing only)
- ✅ Automatic environment detection prevents misconfigurations

**5. Enhanced Tagging Strategy:**
- **Environment-specific tag:** `lambda-fipe-<env>` (e.g., `lambda-fipe-dev`)
- **Latest tag:** `latest` for quick reference
- **Commit SHA tag:** Full commit hash for traceability
- **Build metadata:** Labels include BUILD_DATE, VCS_REF, VERSION

**6. Better Reporting:**
- Step-by-step summaries in GitHub Actions UI
- Comprehensive final summary with all job results
- Clear success/failure indicators per environment
- ECR repository URLs and image tags displayed
- PR-specific notes about build-only behavior

---

### 3. **03 - Build and Push Docker Images** 


**Purpose:** Builds Docker image and pushes to ECR 

**Triggers:**
- Push/PR to `dev`, `stage`, `prod` branches (when `Docker/**` changes)
- Manual dispatch

**What it does:**
- Detects target environment from branch
- Builds Docker image from `./Docker` directory
- Pushes to ECR only on merge (not on PR)
- Posts build status as PR comment

**Features:**
- Matrix strategy for multiple environments
- Auto-generates ECR repo name from GitHub repository
- Tags: `lambda-fipe-<env>`, `latest`

**Recommendation:** Use **02 - Build and Deploy ECR** for new deployments

---

### 4. **04 - Deploy Infrastructure**

**Purpose:** Deploys AWS infrastructure using Terraform

**Triggers:**
- Push/PR to environment branches (when `Terraform/**` changes)
- Manual dispatch
- Can be called by other workflows

**What it does:**
- Waits for Docker build to complete
- Verifies Docker image exists in ECR
- Runs Terraform plan/apply/destroy
- Posts plan as PR comment

**Features:**
- Checks Docker workflow completion via GitHub API
- Validates image presence before deployment
- Auto-apply on merge, plan-only on PR

---

### 5. **Deploy Application** (Unified Deployment)

**Purpose:** Complete end-to-end deployment workflow that intelligently builds Docker images AND deploys infrastructure

**Triggers:**
- Push/PR to environment branches (when `Docker/**` or `Terraform/**` changes)
- Manual dispatch
- Automatically detects what changed and runs only necessary jobs

**What it does:**
- 🔍 **Detects changes** - Analyzes Docker and Terraform file changes
- 🐳 **Builds Docker** - Only if Docker files changed
- 🏗️ **Deploys Infrastructure** - Only if Terraform files changed
- 📊 **Generates summaries** - Comprehensive deployment reports

**Key Features:**
- 🎯 **Smart change detection** - only builds/deploys what changed
- 🔒 **Safety checks** - verifies ECR repo and image exist
- 📊 **PR integration** - posts build status and Terraform plans
- 🏷️ **Multi-tag strategy** - environment, latest, and commit SHA tags
- ⚡ **Efficient** - skips unnecessary steps
- 🔄 **Idempotent** - safe to run multiple times

**Inputs:**
- `environment`: `dev` | `stage` | `prod` (auto-detected from branch)
- `action`: `plan` | `apply` | `destroy`
- `skip_docker_build`: Skip Docker build and use existing image
- `aws_region`: AWS region

---

### 📋 Workflow Recommendations

**For Initial Setup:**
1. ✅ Run **01 - Setup Terraform Backend** (once)
2. ✅ Run **02 - Build and Deploy ECR** with `action: create-and-build`, `environment: all` (once)

**For Day-to-Day Development:**
- ✅ Use **Pull Requests** to environment branches - automatic build and deployment
- ✅ Use **02 - Build and Deploy ECR** for ECR-only operations (rebuild images, create repos)
- ✅ Use **Deploy Application** for full deployments when you need manual control

**Automatic Workflows (No Manual Action Needed):**
- **02 - Build and Deploy ECR** - Triggers on PR/push, builds but doesn't push on PRs
- **03 - Build and Push Docker Images** - Legacy, use workflow 02 instead
- **04 - Deploy Infrastructure** - Triggers on Terraform changes
- **Deploy Application** - Triggers on any changes, intelligently decides what to deploy

---

## Branch Strategy

### Environment Branches

| Branch  | Environment | Deploy Method      | Required Approvals | Auto-Deploy |
|---------|-------------|--------------------|--------------------|-------------|
| `dev`   | Development | PR merge           | 0                  | ✅ Yes      |
| `stage` | Staging     | PR merge           | 1                  | ✅ Yes      |
| `prod`  | Production  | PR merge           | 2+                 | ✅ Yes      |

### Deployment Flow

```
┌──────────────┐
│feature branch│
└──────┬───────┘
       │ PR (build + plan)
       ↓
   ┌───────┐
   │  dev  │ ← Merge = Auto-deploy
   └───┬───┘   Fast iteration, no approvals
       │ PR (build + plan)
       │ Require 1 reviewer
       ↓
   ┌────────┐
   │ stage  │ ← Merge = Auto-deploy
   └────┬───┘   Pre-production testing
       │ PR (build + plan)
       │ Require 2 reviewers + 5min wait
       ↓
   ┌────────┐
   │  prod  │ ← Merge = Auto-deploy
   └────────┘   Production release
```

---

##  Usage Examples

### Example 1: Deploy New Feature to Dev

```bash
# 1. Create feature branch
git checkout -b feature/calculate-discount

# 2. Make changes
vim Docker/src/processa_preco_medio.py

# 3. Commit and push
git add .
git commit -m "feat: add discount calculation"
git push origin feature/calculate-discount

# 4. Create PR to dev
gh pr create --base dev --head feature/calculate-discount \
  --title "feat: add discount calculation" \
  --body "Implements 10% discount for vehicles older than 5 years"

# 5. Review automated PR comments:
#    ✅ Docker Image Build Successful!
#    ✅ Terraform Plan (no changes - only Docker updated)

# 6. Merge PR → Automatic deployment
#    - Docker image pushed to ECR
#    - Lambda updated with new image
#    - Ready in ~2-3 minutes

# 7. Test the deployment
aws s3 cp test-data.csv s3://fipe-input-bucket-dev-<unique-id>/
```

**Note:** If only Docker files changed, Terraform deployment is skipped automatically.

---

### Example 2: Update Infrastructure (Add Environment Variable)

```bash
# 1. Create feature branch
git checkout -b feature/add-timeout-config

# 2. Update Terraform configuration
vim Terraform/environments/dev/main.tf
# Add: timeout = 60  # increased from 30

# 3. Commit and push
git add Terraform/
git commit -m "chore: increase lambda timeout to 60s"
git push origin feature/add-timeout-config

# 4. Create PR to dev
gh pr create --base dev --head feature/add-timeout-config

# 5. Review Terraform plan in PR comments:
#    ~ aws_lambda_function.fipe_lambda will be updated in-place
#      ~ timeout = 30 -> 60

# 6. Merge PR → Automatic apply
```

**Note:** Docker build is skipped automatically since only Terraform changed.

---

### Example 3: Promote from Dev to Stage to Prod

```bash
# After testing in dev, promote to stage
git checkout stage
git pull origin stage

gh pr create --base stage --head dev \
  --title "chore: promote dev to stage" \
  --body "Tested features:\n- Discount calculation\n- Timeout increase"

# Wait for 1 reviewer approval
# Merge → Auto-deploy to STAGE

# Test in stage, then promote to prod
git checkout prod
git pull origin prod

gh pr create --base prod --head stage \
  --title "release: v1.2.0" \
  --body "Production release including:\n- Discount calculation\n- Performance improvements"

# Wait for 2 reviewer approvals + 5 minute safety timer
# Merge → Auto-deploy to PROD
```

---

### Example 4: Hotfix for Production

```bash
# 1. Create hotfix from prod
git checkout prod
git pull origin prod
git checkout -b hotfix/critical-csv-parsing

# 2. Fix the issue
vim Docker/src/lambda_function.py

# 3. Commit and push
git add .
git commit -m "fix: handle malformed CSV rows"
git push origin hotfix/critical-csv-parsing

# 4. PR directly to prod (emergency)
gh pr create --base prod --head hotfix/critical-csv-parsing \
  --title "hotfix: CSV parsing for edge cases" \
  --body "CRITICAL: Fixes production issue with malformed CSV"

# 5. Get 2 approvals (expedited)
# 6. Merge → Deploy to prod

# 7. Backport to lower environments
git checkout stage
git cherry-pick <commit-hash>
git push origin stage

git checkout dev  
git cherry-pick <commit-hash>
git push origin dev
```

---

### Example 5: Manual Deployment (Emergency Override)

```bash
# If you need to deploy without PR:

# 1. Go to GitHub Actions
# 2. Select "Deploy Application"
# 3. Click "Run workflow"
# 4. Configure:
#    - environment: prod
#    - action: apply
#    - skip_docker_build: false (or true if using existing image)
# 5. Run workflow

# Use this ONLY in emergencies
```

---

### Example 6: Rollback Deployment

```bash
# Method 1: Revert the commit
git checkout prod
git revert HEAD
git push origin prod

# Create PR for the revert
gh pr create --base prod --head prod \
  --title "revert: rollback v1.2.0" \
  --body "Rolling back due to <reason>"

# Method 2: Redeploy previous image tag
# Go to GitHub Actions → Deploy Application
# Set skip_docker_build: true
# Lambda will use the existing image (won't create new one)
```

---

## Using the FIPE Processor

### Upload CSV and Process Data

```bash
# Get your bucket names from Terraform output
cd Terraform/environments/dev
terraform output

# Upload CSV file to input bucket
aws s3 cp your-fipe-data.csv s3://fipe-input-bucket-dev-<unique-id>/

# Lambda triggers automatically and processes the file
# Results appear in output bucket within seconds
```

### Monitor Execution

```bash
# Watch CloudWatch Logs in real-time
aws logs tail /aws/lambda/fipe-lambda-dev --follow

# View recent logs
aws logs tail /aws/lambda/fipe-lambda-dev --since 10m

# Search for errors
aws logs tail /aws/lambda/fipe-lambda-dev --filter-pattern "ERROR"
```

### Download Results

```bash
# List processed results
aws s3 ls s3://fipe-output-bucket-dev-<unique-id>/

# Download result JSON
aws s3 cp s3://fipe-output-bucket-dev-<unique-id>/resultado_fipe.json ./

# View result
cat resultado_fipe.json | jq '.'
```



---

## 📁 Project Structure

```
python-app-modernization-lambda/
├── .github/
│   └── workflows/              # GitHub Actions CI/CD pipelines
│       ├── 01-backend.yaml     # Setup Terraform backend (S3 + DynamoDB)
│       ├── 02-build-ecr.yaml   # Create ECR repositories
│       ├── 03-build-push-images.yaml  # Build & push Docker
│       ├── 04-deploy-infrastructure.yaml  # Deploy infrastructure
│       └── deploy.yaml         # 🌟 Unified deployment workflow (recommended)
│
├── Docker/                     # Lambda container image
│   ├── Dockerfile              # Lambda Python 3.11 base image
│   ├── .dockerignore          # Files to exclude from build
│   ├── policy.json            # ECR lifecycle policy
│   └── src/
│       ├── lambda_function.py  # Lambda handler (entry point)
│       └── processa_preco_medio.py  # FIPE processing logic
│
├── Terraform/                  # Infrastructure as Code
│   ├── backend/               # Terraform state backend
│   │   └── backend.tf         # S3 + DynamoDB configuration
│   │
│   ├── environments/          # Environment-specific configs
│   │   ├── dev/
│   │   │   ├── main.tf        # Dev infrastructure
│   │   │   ├── variables.tf   # Dev variables
│   │   │   ├── outputs.tf     # Dev outputs
│   │   │   ├── provider.tf    # AWS provider config
│   │   │   ├── data.tf        # Data sources
│   │   │   └── build/         # ECR repository for dev
│   │   ├── stage/             # Staging environment
│   │   └── prod/              # Production environment
│   │
│   └── modules/               # Reusable Terraform modules
│       ├── ecr/               # ECR repository module
│       ├── iam/               # IAM roles and policies
│       ├── lambda/            # Lambda function module
│       └── s3/                # S3 buckets module
│
├── README.md                   # This file
├── LICENSE                     # MIT License
└── .gitignore                 # Git ignore rules
```

---

## Troubleshooting

### Issue: "ECR repository does not exist"

**Solution:**
```bash
# Run workflow 02 - Build and Deploy ECR
# Option 1: Create ECR only
# Go to Actions → 02 - Build and Deploy ECR
# action: create-only, environment: dev

# Option 2: Create ECR + Build image
# Go to Actions → 02 - Build and Deploy ECR  
# action: create-and-build, environment: dev

# Or manually create via Terraform:
cd Terraform/environments/dev/build
terraform init -var "repository_name=python-app-modernization-lambda"
terraform apply -var "repository_name=python-app-modernization-lambda"
```

---

### Issue: "Docker image not found in ECR"

**Solution:**
```bash
# Verify image exists
aws ecr describe-images \
  --repository-name python-app-modernization-lambda-dev \
  --image-ids imageTag=lambda-fipe-dev

# If missing, rebuild using unified workflow:
# Go to Actions → 02 - Build and Deploy ECR
# action: build-only, environment: dev

# Or use Deploy Application workflow:
# Go to Actions → Deploy Application
# Run with skip_docker_build: false
```

---

### Issue: "Terraform state locked"

**Solution:**
```bash
# Check DynamoDB for lock
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use carefully!)
cd Terraform/environments/dev
terraform force-unlock <LOCK_ID>
```


---

### Issue: Workflow fails with "no changes detected"

**Cause:** Smart change detection skipped jobs because no relevant files changed

**Solution:**
- This is expected behavior and saves time/cost
- To force deployment: Use manual workflow dispatch
- Or trigger by modifying relevant files (Docker or Terraform)

---

## 📊 Monitoring and Logging

### CloudWatch Dashboards

```bash
# View Lambda metrics in AWS Console
# Navigate to: CloudWatch → Dashboards → Create dashboard
```

### Key Metrics to Monitor

- **Lambda Invocations** - How many times function is triggered
- **Lambda Errors** - Failed executions
- **Lambda Duration** - Execution time
- **Lambda Throttles** - Rate limiting events
- **S3 Bucket Size** - Storage usage
- **S3 Request Count** - API calls

### Set Up Alarms

```bash
# Lambda error alarm
aws cloudwatch put-metric-alarm \
  --alarm-name fipe-lambda-errors-dev \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=fipe-lambda-dev

# Lambda duration alarm (approaching timeout)
aws cloudwatch put-metric-alarm \
  --alarm-name fipe-lambda-duration-dev \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --threshold 25000 \
  --comparison-operator GreaterThanThreshold
```

### View Logs

```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/lambda/fipe-lambda-dev \
  --order-by LastEventTime \
  --descending

# Get specific log stream
aws logs get-log-events \
  --log-group-name /aws/lambda/fipe-lambda-dev \
  --log-stream-name '<stream-name>'
```

---

##  Cleanup and Destruction

### Destroy Specific Environment

**Via GitHub Actions:**

```bash
# Go to Actions → Deploy Application
# Run workflow:
#   - environment: dev
#   - action: destroy
```

**Manually:**

```bash
cd Terraform/environments/dev
terraform destroy -auto-approve
```


⚠️ **Warning:** Destroying the backend will delete the Terraform state. Make sure you've destroyed all other resources first, or you'll lose track of them.

---

## 🎯 Best Practices

### Development Workflow

1. ✅ **Always create feature branches** from `dev` (not `main`)
2. ✅ **Use conventional commits**: `feat:`, `fix:`, `chore:`, `docs:`
3. ✅ **Keep PRs small** and focused on single features
4. ✅ **Write descriptive PR descriptions** explaining what and why
5. ✅ **Test thoroughly in dev** before promoting to stage
6. ✅ **Review Terraform plans** carefully in PR comments
7. ✅ **Never commit secrets** - use AWS Secrets Manager or Parameter Store

### Deployment Safety

1. ✅ **Always deploy to dev first** - validate changes work
2. ✅ **Stage is pre-production** - final testing before prod
3. ✅ **Prod requires 2 reviewers** - peer review critical
4. ✅ **Use 5-minute wait timer** on prod - time to cancel if needed
5. ✅ **Have rollback plan ready** before deploying to prod
6. ✅ **Deploy during maintenance windows** for prod changes
7. ✅ **Monitor CloudWatch** after deployment

### Code Review Checklist

When reviewing PRs, verify:

- [ ] Terraform plan shows expected changes only
- [ ] No unexpected resource deletions
- [ ] Docker build succeeded
- [ ] No secrets or credentials in code
- [ ] CloudWatch logs configured properly
- [ ] IAM permissions follow least privilege
- [ ] Resource naming follows convention
- [ ] Tags applied to all resources
- [ ] Costs are reasonable

---

## 🔄 CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     PULL REQUEST OPENED                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │  Setup  │
                    │   Job   │
                    └────┬────┘
                         │
        ┌────────────────┼────────────────┐
        │                                  │
   ┌────▼─────┐                     ┌─────▼──────┐
   │  Docker  │                     │ Terraform  │
   │  Build   │                     │   Plan     │
   │ (if Δ)   │                     │  (if Δ)    │
   └────┬─────┘                     └─────┬──────┘
        │                                  │
        └──────────┬──────────────────────┘
                   │
            ┌──────▼──────┐
            │ Post PR     │
            │ Comments    │
            └─────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      PR MERGED TO BRANCH                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │  Setup  │
                    │   Job   │
                    └────┬────┘
                         │
        ┌────────────────┼────────────────┐
        │                                  │
   ┌────▼─────┐                     ┌─────▼──────┐
   │  Docker  │                     │ Terraform  │
   │  Push    │ ──────────────────> │   Apply    │
   │ (if Δ)   │  Wait for image     │  (if Δ)    │
   └────┬─────┘                     └─────┬──────┘
        │                                  │
        └──────────┬──────────────────────┘
                   │
            ┌──────▼──────┐
            │  Deployment │
            │   Summary   │
            └─────────────┘
```

**Legend:**
- `(if Δ)` = Only runs if changes detected in relevant files
- Setup job detects which components changed
- Docker and Terraform jobs run conditionally
- Infrastructure waits for Docker to complete

---

## ⚙️ GitHub Configuration Requirements

### 1. Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `ROLE_ARN`  | AWS IAM role ARN for OIDC authentication | `arn:aws:iam::123456789012:role/github-actions` |

### 2. Branch Protection Rules

Configure in **Settings → Branches → Branch protection rules**:

**`dev` branch:**
- ✅ Require pull request reviews before merging
- ✅ Require status checks: `setup`, `build-docker`, `deploy-infrastructure`
- ❌ Require approvals: 0
- ✅ Automatically delete head branches

**`stage` branch:**
- ✅ Require pull request reviews: **1 approval**
- ✅ Require status checks to pass
- ✅ Dismiss stale reviews
- ✅ Require conversation resolution

**`prod` branch:**
- ✅ Require pull request reviews: **2 approvals**
- ✅ Require review from Code Owners
- ✅ Require signed commits (recommended)
- ✅ Require linear history
- ❌ Allow force pushes: **disabled**

### 3. Environments

Create in **Settings → Environments**:

| Environment | Wait Timer | Required Reviewers | Deployment Branches |
|-------------|------------|-------------------|---------------------|
| `dev`       | 0 min      | 0                 | Any                 |
| `stage`     | 0 min      | 1                 | `stage` only        |
| `prod`      | 5 min      | 2                 | `prod` only         |

### 4. CODEOWNERS File (Optional)

Create `.github/CODEOWNERS`:

```
# Default owners for everything
* @marcosvlt

# Terraform infrastructure
/Terraform/ @marcosvlt

# Docker and Lambda code  
/Docker/ @marcosvlt

# GitHub workflows
/.github/workflows/ @marcosvlt
```

---

## 📚 Additional Resources

### AWS Documentation
- [Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
- [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)

### Terraform Documentation
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Lambda Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [S3 Bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

### GitHub Actions
- [OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

---
### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `ci:` - CI/CD changes
- `perf:` - Performance improvements

---

## 🔒 Security Features

- ✅ **OIDC Authentication**: No long-lived AWS credentials in GitHub
- ✅ **IAM Least Privilege**: Roles with minimal required permissions
- ✅ **Encrypted S3 Buckets**: Server-side encryption enabled by default
- ✅ **Private ECR Repositories**: Images not publicly accessible
- ✅ **Image Scanning**: ECR vulnerability scanning enabled
- ✅ **CloudWatch Logging**: Complete audit trail of all operations
- ✅ **Terraform State Locking**: Prevents concurrent modifications
- ✅ **Branch Protection**: Required reviews for prod deployments
- ✅ **Signed Commits**: Verified commit authors (optional)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

