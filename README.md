# GitOps CI/CD Pipeline with GitHub Actions, AKS, and Flux CD

This repository implements a complete GitOps workflow for deploying a static web application to Azure Kubernetes Service (AKS) using GitHub Actions for CI and Flux CD for continuous deployment.

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   Developer     │────▶│  GitHub Repo     │────▶│   GitHub Actions    │
│   (Push Code)   │     │  (Source Truth)  │     │   (Build & Push)    │
└─────────────────┘     └──────────────────┘     └──────────┬──────────┘
                                │                           │
                                │ Updates YAML              │ Pushes Image
                                ▼                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  Running App    │◀────│  AKS Cluster     │◀────│  Azure Container    │
│  (Deployed)     │     │  (Flux CD)       │     │  Registry (ACR)     │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
                                ▲
                                │ Watches for changes
                                │
                        ┌───────┴────────┐
                        │   Flux CD      │
                        │   (GitOps)     │
                        └────────────────┘
```

## 📁 Project Structure

```
.
├── app/                          # Application source files
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   └── images/
├── .github/
│   └── workflows/
│       └── ci-cd.yml            # GitHub Actions CI/CD pipeline
├── k8s/
│   └── base/                    # Kubernetes manifests
│       ├── namespace.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
├── flux/                        # Flux CD configuration
│   ├── source.yaml
│   ├── kustomization.yaml
│   └── image-automation.yaml
├── Dockerfile                   # Container image definition
├── nginx.conf                   # Nginx configuration
├── main.tf                      # Terraform infrastructure
└── terraform.tfvars.example     # Example variables file
```

## 🚀 Getting Started

### Prerequisites

- Azure CLI (`az`) installed and logged in
- Terraform installed
- kubectl installed
- Flux CLI installed (`curl -s https://fluxcd.io/install.sh | sudo bash`)
- GitHub account with a personal access token

### Step 1: Deploy Azure Infrastructure

```bash
# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply Terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Configure GitHub Secrets

In your GitHub repository, add these secrets (Settings → Secrets and variables → Actions):

| Secret Name | Description |
|------------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal credentials (JSON) |

And these variables:

| Variable Name | Description |
|--------------|-------------|
| `ACR_NAME` | Your Azure Container Registry name |
| `AZURE_RESOURCE_GROUP` | Your resource group name |

**Create Azure credentials:**

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

### Step 3: Get AKS Credentials and Bootstrap Flux

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-gitops-webapp --name aks-gitops-webapp

# Bootstrap Flux CD
export GITHUB_TOKEN=<your-github-token>

flux bootstrap github \
  --owner=YOUR_GITHUB_USERNAME \
  --repository=YOUR_REPO_NAME \
  --branch=main \
  --path=./flux \
  --personal
```

### Step 4: Update Configuration Files

1. Update `flux/source.yaml` with your GitHub repository URL
2. Update `k8s/base/deployment.yaml` with your ACR name
3. Commit and push changes

## 🔄 How It Works

1. **Developer pushes code** to the `main` branch
2. **GitHub Actions** automatically:
   - Builds a Docker image from the application
   - Pushes the image to Azure Container Registry
   - Updates `k8s/base/deployment.yaml` with the new image tag
   - Commits the change back to the repository
3. **Flux CD** (running in AKS):
   - Detects the change in the repository
   - Pulls the new configuration
   - Applies the updated deployment to the cluster
4. **Kubernetes** pulls the new image and deploys it

## 📋 Useful Commands

```bash
# Check Flux status
flux get all

# Check GitRepository status
flux get sources git

# Check Kustomization status
flux get kustomizations

# Force reconciliation
flux reconcile kustomization gitops-webapp --with-source

# View Flux logs
flux logs

# Check deployment status
kubectl get deployments -n gitops-webapp
kubectl get pods -n gitops-webapp

# View application logs
kubectl logs -l app.kubernetes.io/name=gitops-webapp -n gitops-webapp
```

## 🔧 Troubleshooting

### Image Pull Errors

If pods can't pull images from ACR:

```bash
# Verify AKS has ACR access
az aks check-acr --name aks-gitops-webapp --resource-group rg-gitops-webapp --acr youracrname.azurecr.io
```

### Flux Not Syncing

```bash
# Check source status
flux get sources git

# Check for errors
flux logs --level=error

# Force sync
flux reconcile source git gitops-webapp
```

## 📄 License

MIT License
