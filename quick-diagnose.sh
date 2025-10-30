#!/bin/bash

# Quick diagnostic script for Grafana-Loki connectivity issues
# Run this on a system with kubectl configured for your AKS cluster

NAMESPACE="monitoring"
GRAFANA_POD="prometheus-grafana-655f95f7f7-k48f2"
LOKI_POD="loki-0"

echo "=========================================="
echo "Grafana-Loki Connection Diagnostics"
echo "=========================================="

echo -e "\n=== 1. Checking Pod Status ==="
kubectl get pods -n $NAMESPACE | grep -E "(NAME|grafana|loki)"

echo -e "\n=== 2. Checking Loki Service ==="
echo "Service details:"
kubectl get svc loki -n $NAMESPACE -o wide

echo -e "\nService endpoints:"
kubectl get endpoints loki -n $NAMESPACE

echo -e "\nService configuration:"
kubectl get svc loki -n $NAMESPACE -o jsonpath='{.spec.ports[0]}' | jq .
echo ""

echo -e "\n=== 3. Checking Network Policies ==="
POLICIES=$(kubectl get networkpolicies -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ "$POLICIES" -eq 0 ]; then
    echo "No network policies found in $NAMESPACE namespace"
else
    kubectl get networkpolicies -n $NAMESPACE
fi

echo -e "\n=== 4. Checking Service-to-Pod Label Match ==="
echo "Service selector:"
kubectl get svc loki -n $NAMESPACE -o jsonpath='{.spec.selector}' && echo ""

echo "Loki pod labels:"
kubectl get pod $LOKI_POD -n $NAMESPACE --show-labels

echo -e "\n=== 5. Recent Grafana Logs (last 30 lines) ==="
kubectl logs $GRAFANA_POD -n $NAMESPACE --tail=30

echo -e "\n=== 6. Recent Loki Logs (last 30 lines) ==="
kubectl logs $LOKI_POD -n $NAMESPACE --tail=30

echo -e "\n=== 7. Testing Loki Health Directly ==="
echo "Testing Loki readiness from within Loki pod:"
kubectl exec $LOKI_POD -n $NAMESPACE -- wget -O- --timeout=5 http://localhost:3100/ready 2>&1 | head -5

echo -e "\n=== 8. Testing Connectivity from Grafana to Loki ==="
echo "Test 1: Using service name 'loki'"
kubectl exec $GRAFANA_POD -n $NAMESPACE -- wget -O- --timeout=5 http://loki:3100/ready 2>&1 | head -5

echo -e "\nTest 2: Using fully-qualified domain name"
kubectl exec $GRAFANA_POD -n $NAMESPACE -- wget -O- --timeout=5 http://loki.monitoring.svc.cluster.local:3100/ready 2>&1 | head -5

echo -e "\nTest 3: DNS resolution"
kubectl exec $GRAFANA_POD -n $NAMESPACE -- nslookup loki 2>&1

echo -e "\n=== 9. Checking CoreDNS Status ==="
kubectl get pods -n kube-system | grep -E "(NAME|coredns)"

echo -e "\n=========================================="
echo "Diagnostics Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the outputs above for any errors"
echo "2. Check if Loki endpoints are populated (step 2)"
echo "3. Check if connectivity tests succeed (step 8)"
echo "4. Review Grafana logs for specific error messages (step 5)"
echo ""
