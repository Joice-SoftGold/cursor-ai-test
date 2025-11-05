terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70, < 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region for the AKS deployment"
  type        = string
  default     = "eastus"
}

locals {
  resource_group_name  = "production-aks-rg"
  vnet_name            = "aks-vnetnew"
  subnet_name          = "aks-subnetnew"
  aks_cluster_name     = "prod-cluster-01"
  kubernetes_version   = "1.28.9"
  monitoring_namespace = "monitoring"
}

resource "azurerm_resource_group" "aks" {
  name = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "aks" {
  name                = local.vnet_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  address_space = ["10.240.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name = local.subnet_name

  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.240.0.0/20"]

  delegation {
    name = "aks-delegation"

    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "tls_private_key" "aks_admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "${local.aks_cluster_name}-dns"

  kubernetes_version = local.kubernetes_version

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_B2s"
    node_count          = 2
    vnet_subnet_id      = azurerm_subnet.aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    dns_service_ip    = "10.2.0.10"
    service_cidr      = "10.2.0.0/24"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  linux_profile {
    admin_username = "aksadmin"

    ssh_key {
      key_data = tls_private_key.aks_admin.public_key_openssh
    }
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "production"
    workload    = "observability"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)

  alias = "aks"
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }

  alias = "aks"
}

resource "kubernetes_namespace" "monitoring" {
  provider = kubernetes.aks

  metadata {
    name = local.monitoring_namespace
    labels = {
      "app.kubernetes.io/part-of" = "observability"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_config_map" "grafana_dashboard" {
  provider = kubernetes.aks

  metadata {
    name      = "pod-resources-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      "grafana_dashboard"         = "1"
      "app.kubernetes.io/name"    = "pod-resources"
      "app.kubernetes.io/part-of" = "observability"
    }
  }

  data = {
    "pod-resources-dashboard.json" = file("${path.module}/dashboards/pod-resources-dashboard.json")
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_config_map" "grafana_datasource" {
  provider = kubernetes.aks

  metadata {
    name      = "loki-datasource"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      "grafana_datasource"        = "1"
      "app.kubernetes.io/name"    = "loki"
      "app.kubernetes.io/part-of" = "observability"
    }
  }

  data = {
    "loki-datasource.yaml" = <<-EOT
      apiVersion: 1
      datasources:
        - name: Loki
          type: loki
          access: proxy
          url: http://loki:3100
          isDefault: false
          jsonData:
            maxLines: 1000
    EOT
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "kube_prometheus_stack" {
  provider = helm.aks

  name = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  version = "58.5.0"

  namespace = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      grafana = {
        enabled                  = true
        defaultDashboardsEnabled = true
        sidecar = {
          dashboards = {
            enabled = true
            label   = "grafana_dashboard"
          }
          datasources = {
            enabled                  = true
            defaultDatasourceEnabled = false
            label                    = "grafana_datasource"
          }
        }
      }
      prometheus = {
        prometheusSpec = {
          retention     = "15d"
          retentionSize = "50GiB"
        }
      }
    }),
  ]

  depends_on = [
    kubernetes_config_map.grafana_dashboard,
    kubernetes_config_map.grafana_datasource,
  ]
}

resource "helm_release" "loki_stack" {
  provider = helm.aks

  name = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart = "loki-stack"
  version = "2.10.2"

  namespace = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      grafana = {
        enabled = false
      }
      prometheus = {
        enabled = false
      }
      loki = {
        isDefault = true
      }
    }),
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "kubernetes_network_policy" "allow_grafana_to_loki" {
  provider = kubernetes.aks

  metadata {
    name      = "allow-grafana-to-loki"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "loki"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "grafana"
          }
        }
      }

      ports {
        port     = 3100
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
    helm_release.loki_stack,
  ]
}

output "kube_config" {
  description = "Admin kubeconfig for the AKS cluster"
  value = {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  }
  sensitive = true
}

output "grafana_endpoint" {
  description = "External endpoint for Grafana"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "ssh_public_key" {
  description = "Public SSH key used for the AKS Linux profile"
  value       = tls_private_key.aks_admin.public_key_openssh
}
