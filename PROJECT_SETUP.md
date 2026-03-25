# GCP Organization Bootstrap Setup for Terraform

This guide documents the **recommended enterprise setup for managing GCP organization hierarchy using Terraform**.  
It starts with creating a **dedicated project inside a shared platform folder** to host the Terraform service account that will manage folders and projects in the organization.

The service account will later be used by **GitHub Actions via Workload Identity Federation (OIDC)**.

---

# 1. GCP Resource Hierarchy

Create the following structure in your organization:

```
Organization
│
├── fld-platform-shared
│     └── prj-shared-github-cicd
│           └── sa-github-terraform
│
├── fld-production
│
├── fld-nonproduction
│
└── fld-sandbox
```

### Purpose

| Component | Purpose |
|---|---|
| **fld-platform-shared** | Contains shared platform infrastructure |
| **prj-shared-github-cicd** | Dedicated project for CI/CD identities and automation |
| **sa-github-terraform** | Terraform automation service account |

This project **does not host workloads**. It is used only for:

- Terraform automation
- CI/CD identities
- Workload Identity Federation
- Cross-project infrastructure management

---

# 2. Complete Prerequisite Identity Setup

Before proceeding with organization bootstrap, complete the following identity prerequisites:

1. Sign up for a domain name.
2. Create a Google Workspace for that domain.
3. Create a Google account in the Google Workspace tenant.
4. Log in to Google Cloud using the Google Workspace login ID.

---

# 3. Grant Bootstrap Roles to the Default User

After signing in, grant bootstrap permissions to your default user.

> ⚠️ **Prerequisites**: Complete **Step 4** (Retrieve Organization ID) and **Step 6** (Create CI/CD Project) before running the commands that reference `$ORG_ID` and `$PROJECT_ID`. Roles 1–5 below can be granted once `$ORG_ID` is known; Role 6 and Roles 7–8 require the CI/CD project to exist first.

```bash
USER="user:$(gcloud config get-value account)"

# Role 1 - Organization Administrator
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member=$USER \
  --role="roles/resourcemanager.organizationAdmin"

# Role 2 - Folder Creator
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member=$USER \
  --role="roles/resourcemanager.folderCreator"

# Role 3 - Project Creator
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member=$USER \
  --role="roles/resourcemanager.projectCreator"

# Role 4 - Billing User
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member=$USER \
  --role="roles/billing.user"

# Role 5 - Service Account Admin
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member=$USER \
  --role="roles/iam.serviceAccountAdmin"

# Role 6 - Service Account Key Admin (requires $PROJECT_ID set after Step 6)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:learn-gcp@subhamay.org" \
  --role="roles/iam.serviceAccountKeyAdmin"

# Role 7 - Workload Identity Pool Admin (required to create the WIF pool in Step 14)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=$USER \
  --role="roles/iam.workloadIdentityPoolAdmin"

# Role 8 - IAM Service Account Token Creator (required to impersonate the SA in Step 13)
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --member=$USER \
  --role="roles/iam.serviceAccountTokenCreator"
```

---

# 4. Retrieve Organization ID

Authenticate and retrieve the organization ID.

```bash
gcloud auth login
gcloud organizations list
```

Example output:

```
DISPLAY_NAME        ID
subhamay.cloud      123456789012
```

Store it:

```bash
export ORG_ID=<ORG_ID>
export USER=<USER_ID>
```
> 💡  Example 
```bash
export ORG_ID=464247778313
export USER=user:learn-gcp@subhamay.org
```

---

# 5. Create the Platform Shared Folder

Create a folder to host shared platform services.

```bash
# List the project you have access to, typically this is the default project when you create a GCP account
gcloud projects list --format="value(projectId,projectNumber)"

gcloud resource-manager folders create \
  --display-name="fld-platform-shared" \
  --organization=$ORG_ID
```

Example output:

```
name: folders/123456789012
displayName: fld-platform-shared
```

Store the folder ID:

```bash
export FOLDER_ID="123456789012"
```

---

# 6. Create the CI/CD Identity Project

Create a project inside the **platform shared folder**.

> 💡 Tip To retrieve the folder  id
```
gcloud resource-manager folders list --organization=$ORG_ID --format="table(name,displayName)"

export FOLDER_ID="123456789012"
```
```bash
gcloud projects create prj-shared-github-cicd-$RANDOM \
  --name="prj-shared-github-cicd" \
  --folder=$FOLDER_ID
```

Set the project for CLI usage:

```bash
gcloud config set project prj-shared-github-cicd-<Random Number>
```

Store the project ID and number:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
```

---

# 6.5. Link Billing Account to the CI/CD Project

Before enabling billing-related APIs, the CI/CD project must have a billing account attached.

> ⚠️ Without this step, enabling `cloudbilling.googleapis.com` and `billingbudgets.googleapis.com` in Step 7 will fail.

```bash
gcloud billing projects link $PROJECT_ID \
  --billing-account=$BILLING_ID_1
```

Verify the link:

```bash
gcloud billing projects describe $PROJECT_ID \
  --format="table(projectId,billingAccountName,billingEnabled)"
```

Expected output:

```
PROJECT_ID                      BILLING_ACCOUNT_NAME                        BILLING_ENABLED
prj-shared-github-cicd-16748    billingAccounts/000ABC-123DEF-456GHI        True
```

> 💡 `$BILLING_ID_1` is defined in Step 10. If you are following the steps in order for the first time, run Step 10 first, then return here.

---

# 7. Enable Required APIs

Enable APIs required for IAM, federation, and automation.

```bash
gcloud services enable \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudbilling.googleapis.com \
  billingbudgets.googleapis.com
```

---

# 8. Create Terraform Service Account

Create the service account used by Terraform automation.

```bash
gcloud iam service-accounts create sa-github-terraform \
  --display-name="GitHub Terraform Service Account" \
  --description="Service account used by GitHub Actions via Workload Identity Federation to run Terraform deployments across GCP projects"
```

Verify creation:

```bash
gcloud iam service-accounts list
```

Expected output:

```
DISPLAY NAME: GitHub Terraform Service Account-16748)$ gcloud iam service-accounts list
EMAIL: sa-github-terraform@prj-shared-github-cicd-16748.iam.gserviceaccount.com
DISABLED: False
```

Store the service account email:

```bash
SA_EMAIL="sa-github-terraform@prj-shared-github-cicd-16748.iam.gserviceaccount.com"
```

---

# 9. Grant Organization Roles to the Service Account

### Folder Administration

```bash
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.folderAdmin"
```

### Policy binding:
  
- #### Project Creation

```bash
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.projectCreator"
```

- #### Project IAM Administration

```bash
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.projectIamAdmin"
```

- #### Service Usage Admin (required to enable APIs on newly created projects)

```bash
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/serviceusage.serviceUsageAdmin"
```

---

# 10. Retrieve Billing Account

Projects require a billing account during creation.

```bash
gcloud billing accounts list
```

Example output:

```
ACCOUNT_ID           NAME
000ABC-123DEF-456GHI My Billing Account One
111JKL-222MNO-333PQR My Billing Account Two
```

Store billing ID:

```bash
export BILLING_ID_1="000ABC-123DEF-456GHI"
export BILLING_ID_2="111JKL-222MNO-333PQR"
```

---

# 11. Grant Billing Permission

Allow Terraform to attach billing accounts to new projects.

## Step 11.1 — Enable Cloud Billing API on the CI/CD project
```bash
gcloud services enable cloudbilling.googleapis.com \
  --project=$PROJECT_ID
```

## Step 11.2 — Grant Billing User role on Billing Account Number One and Two
```bash
gcloud billing accounts add-iam-policy-binding $BILLING_ID_1 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.user"

gcloud billing accounts add-iam-policy-binding $BILLING_ID_2 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.user"
```

## Step 11.3 — Grant Billing Costs Manager role on Billing Account Number One and Two
```bash
gcloud billing accounts add-iam-policy-binding $BILLING_ID_1 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.costsManager"

gcloud billing accounts add-iam-policy-binding $BILLING_ID_2 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/billing.costsManager"
```

## Step 11.4 — Verify Billing Role on Billing Account Number One and Two
```bash
gcloud billing accounts get-iam-policy $BILLING_ID_1 \
  --flatten="bindings[].members" \
  --filter="bindings.members:$SA_EMAIL" \
  --format="table(bindings.role)"
```

```bash
gcloud billing accounts get-iam-policy $BILLING_ID_2 \
  --flatten="bindings[].members" \
  --filter="bindings.members:$SA_EMAIL" \
  --format="table(bindings.role)"
```

Expected output:
```
ROLE
roles/billing.user
roles/billing.costsManager
```


# 12. Verify IAM Permissions

Verify organization roles:

```bash
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:$SA_EMAIL" \
  --format="table(bindings.role)"
```

Verify billing permissions:

```bash
gcloud billing accounts get-iam-policy $BILLING_ID_1 \
  --flatten="bindings[].members" \
  --filter="bindings.members:$SA_EMAIL" \
  --format="table(bindings.role)"

gcloud billing accounts get-iam-policy $BILLING_ID_2 \
  --flatten="bindings[].members" \
  --filter="bindings.members:$SA_EMAIL" \
  --format="table(bindings.role)"
```

---

# 13. Test Terraform Service Account Permissions

### Create Test Folder

```bash
gcloud resource-manager folders create \
  --display-name="fld-test-terraform" \
  --organization=$ORG_ID \
  --impersonate-service-account=$SA_EMAIL
```

Save the folder ID:

```bash
export TEST_FOLDER_ID="FOLDER_ID_FROM_OUTPUT"
```

### Create Test Project

```bash
gcloud projects create prj-test-bootstrap-$RANDOM \
  --name="prj-test-bootstrap-$RANDOM" \
  --folder=$TEST_FOLDER_ID \
  --impersonate-service-account=$SA_EMAIL
```

### Attach Billing

```bash
gcloud billing projects link prj-test-bootstrap-25015 \
  --billing-account=$BILLING_ID_1 \
  --impersonate-service-account=$SA_EMAIL
```

---

# 14. Configure GitHub OIDC Authentication (Workload Identity Federation)

This step allows **GitHub Actions to authenticate to GCP without service account keys**.

---

## Retrieve Project Number

Workload Identity Pools require the project number.

```bash
export PROJECT_ID="prj-shared-github-cicd-16748"

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format="value(projectNumber)")
```

---

## 1. Set Required Variables

```bash
export PROJECT_ID="prj-shared-github-cicd-16748"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export POOL_ID="github-actions"
export PROVIDER_ID="github-provider"
export SA_EMAIL="sa-github-terraform@prj-shared-github-cicd-16748.iam.gserviceaccount.com"
```

Define the GitHub organizations you want to trust:

```bash
export GITHUB_ORGS=("subhamay-bhattacharyya" "subhamay-bhattacharyya-tf" "subhamay-bhattacharyya-some-org")
```

---

## Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create github-actions \
  --project=$PROJECT_ID \
  --location=global \
  --display-name="GitHub Actions Pool"
```

---

## Create GitHub OIDC Provider

Replace with your GitHub repository.

```bash
export GITHUB_ORG="YOUR_GITHUB_ORG"
export GITHUB_REPO="YOUR_REPO"
export TRUSTED_GITHUB_ORGS=("YOUR_GITHUB_ORG" "YOUR_SECOND_GITHUB_ORG")
export ATTRIBUTE_CONDITION="assertion.repository_owner=='${TRUSTED_GITHUB_ORGS[0]}' || assertion.repository_owner=='${TRUSTED_GITHUB_ORGS[1]}'"
```

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool=github-actions \
  --display-name="GitHub Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner,attribute.ref=assertion.ref,attribute.actor=assertion.actor" \
  --attribute-condition="$ATTRIBUTE_CONDITION"
```

Optional (recommended) restriction to main branch:

```
assertion.repository=='ORG/REPO' && assertion.ref=='refs/heads/main'
```

---

## Allow GitHub Organizations  to Impersonate the Service Account

Grant `roles/iam.workloadIdentityUser` to each GitHub organization by using `attribute.repository_owner`.

```bash
for ORG in "${GITHUB_ORGS[@]}"; do
  gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --project=$PROJECT_ID \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository_owner/${ORG}"
done
```

Grant `roles/iam.serviceAccountTokenCreator` as well:

```bash
for ORG in "${GITHUB_ORGS[@]}"; do
  gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --project=$PROJECT_ID \
    --role="roles/iam.serviceAccountTokenCreator" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository_owner/${ORG}"
done
```

---

## Retrieve and Store Workload Identity Provider Name

```bash
export WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe github-provider \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool=github-actions \
  --format="value(name)")

echo "WORKLOAD_IDENTITY_PROVIDER=$WORKLOAD_IDENTITY_PROVIDER"
```

Example output:

```
WORKLOAD_IDENTITY_PROVIDER=projects/123456789012/locations/global/workloadIdentityPools/github-actions/providers/github-provider
```

---

## Diagnostic Check (If Provider Is Not Found)

If the provider describe command returns `NOT_FOUND`, run this diagnostic block:

```bash
gcloud config get-value accessibility/screen_reader
gcloud config set accessibility/screen_reader false

echo "Your active configuration is: [$(gcloud config configurations list --filter=is_active:true --format='value(name)')]"
echo "ACTIVE ACCOUNT: $(gcloud config get-value account)"
echo "ACTIVE PROJECT: $(gcloud config get-value project)"
echo "PROJECT_ID VAR:  $PROJECT_ID"

echo "---- Pools in project ----"
gcloud iam workload-identity-pools list \
  --project="$PROJECT_ID" \
  --location=global \
  --format="table(name,displayName,state)"

echo "---- Providers in github-actions pool ----"
gcloud iam workload-identity-pools providers list \
  --project="$PROJECT_ID" \
  --location=global \
  --workload-identity-pool="github-actions" \
  --format="table(name,displayName,state)"

echo "---- Workload Identity Provider name ----"
gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location=global \
  --workload-identity-pool="$POOL_ID" \
  --format="value(name)"

echo "---- Projects (tabular) ----"
gcloud projects list \
  --format="table(projectId:label=PROJECT_ID,name:label=NAME,projectNumber:label=PROJECT_NUMBER,lifecycleState:label=LIFECYCLE_STATE)"

echo "---- Folders in organization (tabular) ----"
gcloud resource-manager folders list \
  --organization="$ORG_ID" \
  --format="table(name:label=FOLDER_ID,displayName:label=DISPLAY_NAME,parent:label=PARENT,state:label=STATE)"
```

If the pool exists but the provider list is empty, create the provider and then run `describe` again.

---

# 15. Configure GitHub Actions Workflow

## Step 15.1 — Set GitHub Repository Secrets

The following values are stored as **GitHub organization-level variables** (not secrets — they are non-sensitive GCP identifiers shared across repositories in the organization).

> 💡 Requires the [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated with org admin access.

| Variable Name | Value Source |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full WIF provider resource path |
| `GCP_BILLING_ACCOUNT_ID` | Billing account ID (e.g. `000ABC-123DEF-456GHI`) |
| `GCP_ORGANIZATION_ID` | GCP organization ID |
| `GCP_SERVICE_ACCOUNT` | Terraform SA email |

```bash
# Use the GitHub organization login name (slug), not the numeric org ID
# Example: "subhamay-bhattacharyya-tf" not "123456789"
export GITHUB_ORG="YOUR_GITHUB_ORG_NAME"

# Org-level variables (available to all repositories in the organization)
gh variable set GCP_WORKLOAD_IDENTITY_PROVIDER \
  --body "$WORKLOAD_IDENTITY_PROVIDER" \
  --org "$GITHUB_ORG"

gh variable set GCP_BILLING_ACCOUNT_ID \
  --body "$BILLING_ID_1" \
  --org "$GITHUB_ORG"

gh variable set GCP_ORGANIZATION_ID \
  --body "$ORG_ID" \
  --org "$GITHUB_ORG"

gh variable set GCP_SERVICE_ACCOUNT \
  --body "$SA_EMAIL" \
  --org "$GITHUB_ORG"

# Store project ID as a repo-level variable (CI/CD project specific)
gh variable set GCP_PROJECT_ID \
  --body "$PROJECT_ID" \
  --org "$GITHUB_ORG"
```

Verify:

```bash
gh variable list --org "$GITHUB_ORG"
```

---

## Step 15.2 — Create the GitHub Actions Workflow

Create a workflow at:

```
.github/workflows/terraform.yml
```

Example (references org-level variables set in Step 15.1):

```yaml
name: Terraform GCP

on:
  push:
    branches: [ main ]

permissions:
  contents: read
  id-token: write

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      - uses: google-github-actions/setup-gcloud@v2

      - name: Verify access
        run: |
          gcloud auth list
          gcloud projects list
```

---

# Required Roles Summary

## Terraform Service Account (`sa-github-terraform`)

| Scope | Role | Purpose |
|---|---|---|
| Organization | `roles/resourcemanager.folderAdmin` | Create and manage folders |
| Organization | `roles/resourcemanager.projectCreator` | Create projects |
| Organization | `roles/resourcemanager.projectIamAdmin` | Assign IAM roles on projects |
| Organization | `roles/serviceusage.serviceUsageAdmin` | Enable APIs on new projects |
| Billing Account | `roles/billing.user` | Attach billing to projects |
| Billing Account | `roles/billing.costsManager` | Monitor and manage billing costs |
| Service Account (self) | `roles/iam.workloadIdentityUser` | Allow GitHub OIDC authentication |
| Service Account (self) | `roles/iam.serviceAccountTokenCreator` | Issue short-lived tokens for impersonation |

## Bootstrap User

| Scope | Role | Purpose |
|---|---|---|
| Organization | `roles/resourcemanager.organizationAdmin` | Manage org-level policies |
| Organization | `roles/resourcemanager.folderCreator` | Create top-level folders |
| Organization | `roles/resourcemanager.projectCreator` | Create projects |
| Organization | `roles/billing.user` | Link billing accounts |
| Organization | `roles/iam.serviceAccountAdmin` | Create service accounts |
| Project (CI/CD) | `roles/iam.serviceAccountKeyAdmin` | Manage service account keys |
| Project (CI/CD) | `roles/iam.workloadIdentityPoolAdmin` | Create Workload Identity Pools and Providers |
| Service Account | `roles/iam.serviceAccountTokenCreator` | Impersonate SA for testing (Step 13) |

---

# Final Result

After completing this setup:

- GitHub Actions can authenticate to GCP using **OIDC**
- No **service account keys** are required
- Terraform can **securely manage the GCP organization hierarchy**
- CI/CD pipelines can deploy infrastructure across projects