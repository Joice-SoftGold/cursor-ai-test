# ✅ Deployment Readiness Checklist

## Files to Commit to Git (MUST HAVE)

### ✅ Core Infrastructure
- [x] `main.tf` - **UPDATED** with all fixes (Loki, Promtail, configurations)
- [x] `promtail-values.yaml` - Promtail configuration
- [ ] `deployment.yml` - Your nginx deployment
- [ ] `dashboards/pod-resources-dashboard.json` - Custom dashboard

### ✅ Documentation
- [x] `MONITORING_SETUP.md` - Complete setup guide
- [x] `README.md` - Project overview (you may need to update this)

### ⚠️ Optional but Recommended
- [ ] `.github/workflows/deploy-aks.yml` - GitHub Actions workflow
- [ ] `.gitignore` - Terraform state files, etc.
- [ ] `terraform.tfvars` - Variable values (don't commit secrets!)

---

## What Will Happen After Redeployment

### ✅ Automatically Recreated (From Terraform)
- AKS cluster
- Prometheus + Grafana
- Loki (with SingleBinary mode)
- Promtail (collecting from ALL namespaces)
- Loki datasource in Grafana
- Custom pod-resources dashboard
- All configurations and fixes

### ❌ Will Be Lost (Manual Work)
- Grafana dashboards you imported manually (13639, 15757, etc.)
- Grafana language preference (will default to browser language)
- Any manual Grafana settings
- All log data (Loki)
- All metrics data (Prometheus)

### 💡 How to Preserve Manual Dashboards

**Option 1: Export and Save**
1. In Grafana, open dashboard
2. Click Share → Export → Save JSON
3. Save to `dashboards/` folder
4. Add ConfigMap in `main.tf` (copy pod_dashboard example)

**Option 2: Use Grafana Backup Tool**
```bash
# Install grafana-backup
pip install grafana-backup

# Backup all dashboards
grafana-backup save --host http://localhost:3000 --token <api-token>

# Restore after redeployment
grafana-backup restore --host http://localhost:3000 --token <api-token>
```

---

## GitHub Actions Setup

### Step 1: Create Service Principal

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-aks" \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

Copy the output JSON.

### Step 2: Add GitHub Secrets

In your GitHub repo: Settings → Secrets → Actions → New repository secret

Add these secrets from the JSON output:
- `AZURE_CLIENT_ID` → clientId
- `AZURE_CLIENT_SECRET` → clientSecret
- `AZURE_SUBSCRIPTION_ID` → subscriptionId
- `AZURE_TENANT_ID` → tenantId

### Step 3: Create Workflow File

```bash
mkdir -p .github/workflows
cat <<'EOF' > .github/workflows/deploy-aks.yml
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
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: |
            {
              "clientId": "${{ secrets.AZURE_CLIENT_ID }}",
              "clientSecret": "${{ secrets.AZURE_CLIENT_SECRET }}",
              "subscriptionId": "${{ secrets.AZURE_SUBSCRIPTION_ID }}",
              "tenantId": "${{ secrets.AZURE_TENANT_ID }}"
            }
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
      
      - name: Get Grafana Password
        if: success()
        run: |
          az aks get-credentials --resource-group softgold-newresource-group --name Infra-AKSnew --overwrite-existing
          echo "::add-mask::$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 --decode)"
          echo "Grafana Admin Password saved as secret"

EOF
```

### Step 4: Commit and Push

```bash
git add .
git commit -m "Add complete AKS monitoring stack with all fixes"
git push origin main
```

GitHub Actions will automatically deploy!

---

## Testing After Redeployment

### 1. Verify All Pods Running

```bash
kubectl get pods -n monitoring
```

Expected output:
```
NAME                                                     READY   STATUS    RESTARTS   AGE
loki-0                                                   2/2     Running   0          5m
loki-canary-xxx                                          1/1     Running   0          5m
loki-gateway-xxx                                         1/1     Running   0          5m
prometheus-grafana-xxx                                   3/3     Running   0          5m
prometheus-kube-prometheus-operator-xxx                  1/1     Running   0          5m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          5m
promtail-xxx (2 pods - one per node)                     1/1     Running   0          5m
```

### 2. Verify Promtail is Collecting

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=20 | grep "tail routine: started"
```

Should see logs from all namespaces including `default`.

### 3. Verify Loki Has Logs

```bash
kubectl port-forward -n monitoring svc/loki-gateway 3100:80 &
curl -G "http://127.0.0.1:3100/loki/api/v1/label/namespace/values" | jq
```

Should return:
```json
{
  "status": "success",
  "data": ["default", "kube-system", "monitoring"]
}
```

### 4. Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Open: http://localhost:3000

### 5. Test Loki Query in Grafana

Explore → Loki → Query: `{namespace="default"}`

Should see logs!

---

## Quick Reference Commands

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Check Loki logs
curl -G "http://127.0.0.1:3100/loki/api/v1/label/namespace/values" | jq

# Generate test traffic
kubectl exec -it deployment/nginx-from-chatops -- curl localhost

# View Promtail logs
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50

# Delete and redeploy
terraform destroy -auto-approve && terraform apply -auto-approve
```

---

## Summary

### ✅ What You MUST Do:

1. **Commit updated `main.tf`** to Git (includes all fixes)
2. **Commit `promtail-values.yaml`** to Git
3. **Commit `MONITORING_SETUP.md`** to Git
4. **(Optional) Set up GitHub Actions** for automated deployment

### ✅ After Redeployment:

1. Wait 5 minutes for all pods to start
2. Import dashboards manually (13639, 15757, 1860)
3. Set Grafana language to English (if needed)
4. Everything else will work automatically!

### ⚠️ Important:

**Your current setup has manual changes NOT in Git!**
- Updated `main.tf` is now in `/workspace/main.tf` ← COMMIT THIS!
- Promtail was installed manually ← NOW IN TERRAFORM!
- Loki was upgraded manually ← NOW IN TERRAFORM!

**Commit these files to Git NOW or you'll lose all fixes!**

---

## Next Steps

1. Review the updated `main.tf` file
2. Commit all files to Git
3. Test redeployment in a test environment (optional)
4. Set up GitHub Actions (optional)
5. Document any custom dashboards you create

**Need help with any of these steps? Let me know!**
