# main.tf - AKS + VNet + Subnet + Automated Monitoring & Logging (UPDATED WITH ALL FIXES)

# -------------------------
# Providers
# -------------------------

terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    helm    = { source = "hashicorp/helm", version = "~> 2.5" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.11" }
  }
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# -------------------------
# Azure Resources
# -------------------------

resource "azurerm_resource_group" "rg" {
  name     = "softgold-newresource-group"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnetnew"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "aks-subnetnew"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "Infra-AKSnew"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "infraaks"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.2.0.0/16"
    dns_service_ip    = "10.2.0.10"
  }

  tags = {
    Environment = "POC"
  }
}

# -------------------------
# Helm Releases
# -------------------------

# Installs Prometheus + Grafana
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  # Enable sidecar for auto-loading datasources
  set {
    name  = "grafana.sidecar.datasources.enabled"
    value = "true"
  }

  # Enable sidecar for auto-loading dashboards
  set {
    name  = "grafana.sidecar.dashboards.enabled"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Installs Loki with FIXED configuration (SingleBinary mode, optimized for small clusters)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = "monitoring"
  version    = "6.41.1"  # Use the new chart version

  # CRITICAL: Disable Grafana from Loki chart
  set {
    name  = "deploymentMode"
    value = "SingleBinary"
  }

  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }

  set {
    name  = "loki.storage.type"
    value = "filesystem"
  }

  # SingleBinary configuration
  set {
    name  = "singleBinary.replicas"
    value = "1"
  }

  set {
    name  = "singleBinary.persistence.enabled"
    value = "true"
  }

  set {
    name  = "singleBinary.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "singleBinary.persistence.storageClass"
    value = "managed-csi"
  }

  set {
    name  = "singleBinary.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "singleBinary.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "singleBinary.resources.limits.memory"
    value = "1Gi"
  }

  # Disable distributed components
  set {
    name  = "read.replicas"
    value = "0"
  }

  set {
    name  = "write.replicas"
    value = "0"
  }

  set {
    name  = "backend.replicas"
    value = "0"
  }

  # Disable memory-hungry caches (THIS WAS THE MAIN FIX!)
  set {
    name  = "chunksCache.enabled"
    value = "false"
  }

  set {
    name  = "resultsCache.enabled"
    value = "false"
  }

  # Gateway configuration
  set {
    name  = "gateway.enabled"
    value = "true"
  }

  set {
    name  = "gateway.replicas"
    value = "1"
  }

  # Disable test
  set {
    name  = "test.enabled"
    value = "false"
  }

  depends_on = [helm_release.prometheus]
}

# Installs Promtail (Log Shipper) - THIS WAS MISSING!
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = "monitoring"

  # Configure Promtail to send logs to Loki
  set {
    name  = "config.clients[0].url"
    value = "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
  }

  # Ensure Promtail collects from ALL namespaces (including default)
  values = [
    <<-EOT
    config:
      snippets:
        scrapeConfigs: |
          - job_name: kubernetes-pods
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_namespace]
                target_label: namespace
              - source_labels: [__meta_kubernetes_pod_name]
                target_label: pod
              - source_labels: [__meta_kubernetes_pod_container_name]
                target_label: container
              - source_labels: [__meta_kubernetes_pod_node_name]
                target_label: node_name
              - source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
                target_label: __path__
                separator: /
                replacement: /var/log/pods/*$1/*.log
            pipeline_stages:
              - cri: {}
    EOT
  ]

  depends_on = [helm_release.loki]
}

# -------------------------
# Grafana Automation
# -------------------------

# Automatically adds your custom dashboard to Grafana
resource "kubernetes_config_map" "pod_dashboard" {
  depends_on = [helm_release.prometheus]

  metadata {
    name      = "pod-resources-dashboard-cm"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "pod-resources-dashboard.json" = file("${path.module}/dashboards/pod-resources-dashboard.json")
  }
}

# Automatically adds Loki as a data source in Grafana
resource "kubernetes_config_map" "grafana_loki_datasource" {
  depends_on = [helm_release.loki]

  metadata {
    name      = "grafana-datasource-loki"
    namespace = "monitoring"
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "loki-datasource.yaml" = <<EOF
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki-gateway.monitoring.svc.cluster.local
    isDefault: false 
EOF
  }
}

# -------------------------
# NETWORKING FIX
# -------------------------

resource "kubernetes_network_policy" "allow_grafana_to_loki" {
  depends_on = [helm_release.prometheus, helm_release.loki]

  metadata {
    name      = "allow-grafana-to-loki"
    namespace = "monitoring"
  }

  spec {
    pod_selector {
      match_labels = {
        app     = "loki"
        release = "loki"
      }
    }
    
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/instance" = "prometheus"
            "app.kubernetes.io/name"     = "grafana"
          }
        }
      }
      
      ports {
        port     = "3100"
        protocol = "TCP"
      }
    }
  }
}

# -------------------------
# Outputs
# -------------------------

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "grafana_admin_password_command" {
  value = "kubectl get secret -n monitoring prometheus-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode"
}
