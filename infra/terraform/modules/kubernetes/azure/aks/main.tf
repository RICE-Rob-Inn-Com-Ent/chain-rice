# =============================================================================
# AZURE AKS CLUSTER MODULE
# =============================================================================

# Resource Group (if not provided)
resource "azurerm_resource_group" "main" {
  count    = var.resource_group_name == "" ? 1 : 0
  name     = "${var.cluster_name}-rg"
  location = var.location

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.resource_group_name != "" ? data.azurerm_resource_group.main[0].location : azurerm_resource_group.main[0].location
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
  dns_prefix          = var.dns_prefix != "" ? var.dns_prefix : var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = 1
    vm_size             = "Standard_D2s_v3"
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    os_disk_size_gb     = 30
    vnet_subnet_id      = var.subnet_id
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    load_balancer_sku = var.load_balancer_sku
  }

  # RBAC
  role_based_access_control_enabled = var.enable_rbac

  # API Server
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  # Private cluster
  private_cluster_enabled = var.enable_private_cluster

  # Addons
  addon_profile {
    http_application_routing {
      enabled = var.enable_http_application_routing
    }

    oms_agent {
      enabled                    = var.enable_oms_agent
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }

    azure_policy {
      enabled = var.enable_azure_policy
    }
  }

  # Auto-scaling
  automatic_channel_upgrade = var.automatic_channel_upgrade
  
  # Enable cluster autoscaler
  auto_scaler_profile {
    enabled = true
    min_count = 1
    max_count = 10
    scale_down_delay_after_add = "10m"
    scale_down_unneeded = "10m"
    scale_down_utilization_threshold = "0.5"
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = var.maintenance_day
      hours = var.maintenance_hours
    }
    not_allowed {
      start = var.maintenance_not_allowed_start
      end   = var.maintenance_not_allowed_end
    }
  }

  # Tags
  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  enable_auto_scaling   = each.value.enable_auto_scaling
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_type               = each.value.os_type
  os_sku                = each.value.os_sku
  vnet_subnet_id        = var.subnet_id

  node_labels = merge(
    var.labels,
    each.value.labels
  )

  node_taints = each.value.taints

  tags = merge(
    var.tags,
    each.value.tags
  )
}

# Data source for existing resource group
data "azurerm_resource_group" "main" {
  count = var.resource_group_name != "" ? 1 : 0
  name  = var.resource_group_name
}

