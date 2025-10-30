# Grafana-Loki Connection Troubleshooting Guide

## Problem Summary
- **Goal**: Connect Grafana to Loki data source in the same AKS cluster (monitoring namespace)
- **Current Status**: Connection fails even after correcting URL to `http://loki:3100`
- **Previous Issue**: Was using wrong port (8080 instead of 3100) - now fixed

## Prerequisites
Ensure you have kubectl configured to access your AKS cluster:
```bash
# If not already configured, get AKS credentials
az aks get-credentials --resource-group <your-resource-group> --name <your-aks-cluster>

# Verify connection
kubectl cluster-info
kubectl get nodes
```

---

## Step 1: Check Grafana Pod Logs

Get the latest logs to see the new error after correcting to port 3100:

```bash
# Get recent logs
kubectl logs prometheus-grafana-655f95f7f7-k48f2 -n monitoring --tail=100

# Follow logs in real-time (useful when testing connection)
kubectl logs prometheus-grafana-655f95f7f7-k48f2 -n monitoring -f
```

**What to look for:**
- HTTP connection errors
- Timeout messages
- DNS resolution failures
- Authentication errors

---

## Step 2: Verify Loki Service Configuration

```bash
# Get detailed service information
kubectl describe service loki -n monitoring

# Check service endpoints
kubectl get endpoints loki -n monitoring

# List all services in monitoring namespace
kubectl get svc -n monitoring
```

**What to verify:**
- Service exists and has correct name
- Service is listening on port 3100
- Service has valid endpoints (should show Loki pod IP)
- Service type is ClusterIP (for internal communication)

**Expected output for endpoints:**
```
NAME   ENDPOINTS           AGE
loki   10.x.x.x:3100       Xd
```

If endpoints are empty (`<none>`), the service selector might not match the Loki pod labels.

---

## Step 3: Test Direct Connectivity from Grafana Pod

Execute into the Grafana pod and test the connection:

```bash
# Exec into Grafana pod
kubectl exec -it prometheus-grafana-655f95f7f7-k48f2 -n monitoring -- /bin/sh

# Once inside the pod, run these tests:
# Test 1: Check if Loki DNS resolves
nslookup loki

# Test 2: Test connectivity to Loki ready endpoint
curl -v http://loki:3100/ready

# Test 3: Check if port 3100 is accessible
nc -zv loki 3100

# Test 4: Try to query Loki API
curl -v http://loki:3100/loki/api/v1/labels

# Exit the pod
exit
```

**Expected successful responses:**
- `/ready` endpoint: Should return status 200 with "ready" message
- `/loki/api/v1/labels` endpoint: Should return JSON with available labels

**Common failure scenarios:**
- **DNS resolution fails**: Service name might be incorrect or DNS issue
- **Connection refused**: Service might not be listening on port 3100
- **Connection timeout**: Network policy or firewall blocking traffic
- **404 Not Found**: Service is running but Loki API not properly configured

---

## Step 4: Check for Network Policies

Network policies can block traffic between pods:

```bash
# List all network policies in monitoring namespace
kubectl get networkpolicies -n monitoring

# If any exist, describe them
kubectl describe networkpolicy <policy-name> -n monitoring

# Check network policies in all namespaces (in case of global policies)
kubectl get networkpolicies --all-namespaces
```

**What to check:**
- Are there any policies that affect the monitoring namespace?
- Do policies allow ingress to Loki on port 3100?
- Do policies allow egress from Grafana?

---

## Step 5: Verify Loki Pod is Healthy

```bash
# Check Loki pod status
kubectl get pods -n monitoring | grep loki

# Get detailed pod information
kubectl describe pod loki-0 -n monitoring

# Check Loki logs
kubectl logs loki-0 -n monitoring --tail=50

# Test Loki readiness directly
kubectl exec -it loki-0 -n monitoring -- wget -O- http://localhost:3100/ready
```

**What to verify:**
- Pod is in Running state
- Pod has 1/1 containers ready
- No restart loops
- Loki logs show it's listening on port 3100

---

## Step 6: Check Service Port Mapping

Verify the service is correctly mapping to the pod:

```bash
# Get service details in YAML format
kubectl get service loki -n monitoring -o yaml

# Check pod labels
kubectl get pod loki-0 -n monitoring --show-labels

# Verify service selector matches pod labels
kubectl get service loki -n monitoring -o jsonpath='{.spec.selector}'
```

**What to verify:**
- Service selector labels match pod labels
- Service port (3100) maps to container port (3100)
- Service targetPort is correct

---

## Step 7: Test Service from Another Pod

Create a test pod to verify connectivity:

```bash
# Create a temporary test pod
kubectl run test-pod --image=curlimages/curl:latest -n monitoring --rm -it -- /bin/sh

# Once inside, test Loki connection
curl -v http://loki:3100/ready
curl -v http://loki.monitoring.svc.cluster.local:3100/ready

# Exit (pod will be automatically deleted)
exit
```

---

## Step 8: Check Grafana Data Source Configuration

Verify the exact URL being used in Grafana:

```bash
# Get Grafana configuration (if stored as ConfigMap)
kubectl get configmap -n monitoring | grep grafana

# Check if data sources are configured via ConfigMap
kubectl describe configmap <grafana-config-name> -n monitoring
```

**Recommended Loki URLs to try (in order of preference):**
1. `http://loki:3100` (simple service name)
2. `http://loki.monitoring:3100` (namespace-qualified)
3. `http://loki.monitoring.svc.cluster.local:3100` (fully-qualified)

---

## Common Issues and Solutions

### Issue 1: DNS Resolution Fails
**Symptoms:** `nslookup loki` fails inside Grafana pod

**Solutions:**
- Use fully-qualified domain name: `http://loki.monitoring.svc.cluster.local:3100`
- Check CoreDNS pods are running: `kubectl get pods -n kube-system | grep coredns`
- Check if service exists: `kubectl get svc loki -n monitoring`

### Issue 2: Connection Timeout
**Symptoms:** Request hangs and eventually times out

**Solutions:**
- Check for network policies blocking traffic
- Verify Loki pod is running and healthy
- Check service endpoints are populated
- Verify firewall rules (if applicable)

### Issue 3: Connection Refused
**Symptoms:** Immediate connection refused error

**Solutions:**
- Verify Loki is listening on port 3100 (check Loki logs)
- Verify service port mapping is correct
- Check if Loki container is actually running

### Issue 4: 404 Not Found
**Symptoms:** Connection succeeds but returns 404

**Solutions:**
- Verify Loki configuration is correct
- Check Loki logs for startup errors
- Try different endpoints: `/ready`, `/metrics`, `/loki/api/v1/labels`

---

## Quick Diagnostic Script

Save this as a script and run it for quick diagnostics:

```bash
#!/bin/bash

NAMESPACE="monitoring"
GRAFANA_POD="prometheus-grafana-655f95f7f7-k48f2"
LOKI_POD="loki-0"

echo "=== Checking Pods ==="
kubectl get pods -n $NAMESPACE | grep -E "(grafana|loki)"

echo -e "\n=== Checking Loki Service ==="
kubectl get svc loki -n $NAMESPACE
kubectl get endpoints loki -n $NAMESPACE

echo -e "\n=== Checking Network Policies ==="
kubectl get networkpolicies -n $NAMESPACE

echo -e "\n=== Recent Grafana Logs ==="
kubectl logs $GRAFANA_POD -n $NAMESPACE --tail=20

echo -e "\n=== Recent Loki Logs ==="
kubectl logs $LOKI_POD -n $NAMESPACE --tail=20

echo -e "\n=== Testing Connectivity from Grafana to Loki ==="
kubectl exec $GRAFANA_POD -n $NAMESPACE -- wget -O- --timeout=5 http://loki:3100/ready 2>&1
```

Make it executable and run:
```bash
chmod +x diagnose.sh
./diagnose.sh
```

---

## Next Steps After Running Diagnostics

1. **Review the outputs** from each step above
2. **Identify the failure point** (DNS, connection, HTTP response, etc.)
3. **Apply the appropriate solution** based on the issue identified
4. **Test the connection** again in Grafana UI
5. **If still failing**, collect all outputs and review for patterns

---

## Additional Resources

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Kubernetes Service DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Grafana Data Sources](https://grafana.com/docs/grafana/latest/datasources/)

---

## Notes for This Troubleshooting Session

- ✅ Confirmed pods are running
- ✅ Fixed URL from port 8080 to 3100
- ⏳ Need to check new error message in Grafana logs
- ⏳ Need to verify service configuration
- ⏳ Need to test direct connectivity
- ⏳ Need to check for network policies
