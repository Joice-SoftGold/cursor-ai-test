# AKS Monitoring Stack - Complete Setup

This repository contains the complete, production-ready monitoring stack for AKS with all fixes applied.

## What's Included

### ✅ Infrastructure (Terraform)
- **AKS Cluster** - 2-node cluster (Standard_B2s)
- **VNet & Subnet** - Network configuration
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **Loki** - Log aggregation and storage (SingleBinary mode, optimized for 4GB nodes)
- **Promtail** - Log shipping from all namespaces

### ✅ Key Fixes Applied
1. **Memory Issue Fixed** - Disabled chunksCache and resultsCache (prevented 9.6GB pod on 4GB nodes)
2. **Promtail Installed** - Collects logs from ALL namespaces (including default)
3. **SingleBinary Mode** - Loki runs as single pod, suitable for small clusters
4. **Proper Configuration** - Filesystem storage, correct schema config
5. **Network Policies** - Grafana can communicate with Loki

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- kubectl installed
- Access to Azure subscription

## Deployment

### 1. Clone Repository

```bash
git clone <your-repo>
cd <your-repo>
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply (create AKS cluster and monitoring stack)
terraform apply -auto-approve
```

### 3. Configure kubectl

```bash
# Get AKS credentials
az aks get-credentials --resource-group softgold-newresource-group --name Infra-AKSnew

# Verify connection
kubectl get nodes
```

### 4. Wait for All Pods to be Ready

```bash
kubectl get pods -n monitoring -w
```

Wait until all pods show `Running` status (takes ~3-5 minutes).

### 5. Access Grafana

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser
# URL: http://localhost:3000
# Username: admin
# Password: (from command above)
```

## What Gets Deployed

### Monitoring Stack Components

| Component | Type | Purpose | Resource Limits |
|-----------|------|---------|-----------------|
| **Prometheus** | StatefulSet | Metrics collection | Default |
| **Grafana** | Deployment | Visualization | Default |
| **Loki** | StatefulSet (SingleBinary) | Log storage | 512Mi-1Gi RAM |
| **Loki Gateway** | Deployment | HTTP routing | 128Mi-256Mi RAM |
| **Promtail** | DaemonSet | Log shipping | Per-node |
| **Node Exporter** | DaemonSet | Node metrics | Per-node |
| **Kube-State-Metrics** | Deployment | K8s metrics | Default |
| **Alertmanager** | StatefulSet | Alert handling | Default |

### Storage

| Component | Storage Type | Size | Persistent |
|-----------|-------------|------|------------|
| **Loki** | Azure Managed Disk | 10Gi | Yes ✅ |
| **Prometheus** | Node Local Disk | ~26GB | No ❌ |

## Using the Monitoring Stack

### View Metrics (Prometheus)

1. Go to Grafana → Explore
2. Select **"Prometheus"** data source
3. Try query: `container_memory_usage_bytes{pod=~"nginx.*"}`

### View Logs (Loki)

1. Go to Grafana → Explore
2. Select **"Loki"** data source
3. Try query: `{namespace="default"}`

### Import Pre-Built Dashboards

**In Grafana:** Dashboards → Import

- **15757** - Kubernetes Cluster Monitoring
- **15760** - Pod Resource Monitoring
- **1860** - Node Exporter Full
- **13639** - Loki Logs Browser

### Useful Loki Queries

```logql
# All logs from default namespace (your apps)
{namespace="default"}

# Find errors across all namespaces
{namespace=~".+"} |~ "(?i)error|exception|fail"

# Nginx access logs
{pod=~"nginx-from-chatops.*"}

# Real-time streaming (click "Live" button)
{namespace="default"}

# Request rate graph
sum(rate({namespace="default"}[1m]))
```

## Troubleshooting

### Check All Pods Status

```bash
kubectl get pods -n monitoring
```

All pods should be `Running` and `Ready`.

### Check Promtail is Collecting Logs

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50
```

You should see: `"tail routine: started" path=/var/log/pods/...`

### Check Loki Has Logs

```bash
# Port-forward Loki Gateway
kubectl port-forward -n monitoring svc/loki-gateway 3100:80 &

# Query labels
curl -G "http://127.0.0.1:3100/loki/api/v1/label/namespace/values" | jq

# Should show: ["default", "kube-system", "monitoring"]
```

### Generate Test Logs

```bash
# Deploy test nginx
kubectl create deployment nginx-test --image=nginx --replicas=2

# Generate traffic
kubectl exec -it deployment/nginx-test -- curl localhost

# Check logs in Grafana
# Query: {pod=~"nginx-test.*"}
```

## GitHub Actions Deployment

To deploy via GitHub Actions, add this workflow:

```yaml
# .github/workflows/deploy-aks.yml
name: Deploy AKS Monitoring Stack

on:
  push:
    branches: [ main ]
  workflow_dispatch:

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Plan
        run: terraform plan
        
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### Required GitHub Secrets

Add these secrets to your repository:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`

## What Will Persist vs What Will Be Lost

### ✅ Persists (Recreated Automatically)

- AKS cluster configuration
- All Helm releases (Prometheus, Grafana, Loki, Promtail)
- Loki datasource in Grafana
- Custom dashboards in `dashboards/` folder
- Network policies
- ConfigMaps

### ❌ Lost on Cluster Deletion

- **Loki log data** - Azure disk deleted
- **Prometheus metrics data** - Not persistent in current config
- **Manually created Grafana dashboards** - Not in code
- **Grafana preferences** - Language, UI settings
- **Manual Helm upgrades** - Not in Terraform

### 💾 To Persist Grafana Dashboards

**Option 1: Export and save to Git**

1. In Grafana, go to dashboard
2. Click share icon → Export → Save JSON
3. Save to `dashboards/my-dashboard.json`
4. Add ConfigMap in Terraform (like pod_dashboard example)

**Option 2: Use Grafana Dashboard Provisioning**

Already configured! Dashboards in `dashboards/` folder are auto-loaded.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AKS CLUSTER                          │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                 │
│  │   Your App   │    │  Node Exp.   │                 │
│  │   (nginx)    │    │  (metrics)   │                 │
│  └──────┬───────┘    └──────┬───────┘                 │
│         │                   │                          │
│         │ logs              │ metrics                  │
│         ▼                   ▼                          │
│  ┌──────────────┐    ┌──────────────┐                 │
│  │  Promtail    │    │  Prometheus  │                 │
│  │  (DaemonSet) │    │  (scrapes)   │                 │
│  └──────┬───────┘    └──────┬───────┘                 │
│         │ push              │ stores                   │
│         ▼                   ▼                          │
│  ┌──────────────┐    ┌──────────────┐                 │
│  │     Loki     │    │  Prometheus  │                 │
│  │  (stores)    │    │   TSDB       │                 │
│  └──────┬───────┘    └──────┬───────┘                 │
│         │                   │                          │
│         └───────┬───────────┘                          │
│                 │ queries                              │
│                 ▼                                      │
│         ┌──────────────┐                               │
│         │   Grafana    │                               │
│         │ (visualizes) │                               │
│         └──────────────┘                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Cost Optimization

This setup is optimized for small clusters:

- **Node Size:** Standard_B2s (4GB RAM, 2 vCPU) × 2 nodes
- **Loki:** SingleBinary mode (512Mi-1Gi)
- **Caches:** Disabled (saves 9.6GB!)
- **Storage:** 10Gi for logs (expandable)

**Estimated Monthly Cost:** ~$70-100 USD (Azure eastus region)

## Cleanup

```bash
# Delete everything
terraform destroy -auto-approve
```

This will:
- Delete AKS cluster
- Delete all pods and services
- Delete Azure disks (logs and metrics data)
- Delete VNet and subnet
- Delete resource group

## Support

For issues or questions:
1. Check Troubleshooting section
2. Review Terraform logs: `terraform apply -auto-approve | tee deploy.log`
3. Check pod logs: `kubectl logs -n monitoring <pod-name>`

## License

[Your License]

## Credits

Built with:
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Loki](https://grafana.com/oss/loki/)
- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts)
