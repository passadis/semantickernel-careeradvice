# Create Randomness
resource "random_string" "str-name" {
  length  = 5
  upper   = false
  numeric = false
  lower   = true
  special = false
}

# Create a resource group
resource "azurerm_resource_group" "rgdemo" {
  name     = "rg-mybotapp"
  location = "swedencentral"
}

data "azurerm_resource_group" "rgdemo" {
  name = azurerm_resource_group.rgdemo.name
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "Logskp"
  location            = azurerm_resource_group.rgdemo.location
  resource_group_name = azurerm_resource_group.rgdemo.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Create Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "appin${random_string.str-name.result}"
  location            = azurerm_resource_group.rgdemo.location
  resource_group_name = azurerm_resource_group.rgdemo.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "other"
}

output "instrumentation_key" {
  value     = azurerm_application_insights.appinsights.instrumentation_key
  sensitive = true
}

output "app_id" {
  value     = azurerm_application_insights.appinsights.app_id
  sensitive = true
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "azr${random_string.str-name.result}"
  resource_group_name = azurerm_resource_group.rgdemo.name
  location            = azurerm_resource_group.rgdemo.location
  sku                 = "Standard"
  admin_enabled       = true
  depends_on          = [azurerm_role_assignment.rbac2]
}

output "acrname" {
  value = azurerm_container_registry.acr.name
}


# Create a Storage Account 
resource "azurerm_storage_account" "storage" {
  name                     = "s${random_string.str-name.result}01"
  resource_group_name      = azurerm_resource_group.rgdemo.name
  location                 = azurerm_resource_group.rgdemo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "userid" {
  location            = azurerm_resource_group.rgdemo.location
  name                = "uid${random_string.str-name.result}"
  resource_group_name = azurerm_resource_group.rgdemo.name
}


# Create Azure Container App Environment
resource "azurerm_container_app_environment" "acaenv" {
  name                       = "mgmt-env-apps"
  location                   = azurerm_resource_group.rgdemo.location
  resource_group_name        = azurerm_resource_group.rgdemo.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

#Certificate
resource "azurerm_container_app_environment_certificate" "cert" {
  name                         = "azuredev"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  certificate_blob_base64      = filebase64("xxxxxxxxxx.pfx")
  certificate_password         = "xxxxxxxxxxxxxx"
}


# Create Azure Container App - Frontend
resource "azurerm_container_app" "careerapp" {
  name                         = "careerapp"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  resource_group_name          = azurerm_resource_group.rgdemo.name
  revision_mode                = "Single"

  template {
    container {
      name   = "careerapp"
      image  = "${azurerm_container_registry.acr.login_server}/careerapp:v30"
      cpu    = 1
      memory = "2Gi"
    }
    min_replicas = 1
    max_replicas = 3
  }
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "http"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }

  }
      registry {
      server  = azurerm_container_registry.acr.login_server
      username = azurerm_container_registry.acr.admin_username
      password_secret_name = azurerm_container_registry.acr.admin_password
    }
  depends_on = [null_resource.run_azcli_script1]
}


# Create Azure Container App - Backend
resource "azurerm_container_app" "webapi" {
  name                         = "webapi"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  resource_group_name          = azurerm_resource_group.rgdemo.name
  revision_mode                = "Single"

  template {
    container {
      name   = "webapi"
      image  = "${azurerm_container_registry.acr.login_server}/webapi:v30"
      cpu    = 1
      memory = "2Gi"
      env {
        name  = "ALLOWED_ORIGINS"
        value = "https://xxxxxxxxxxx.azuredev.online"
      }
      env {
        name  = "OPENAI_ENDPOINT"
        value = var.openai_endpoint
      }
      env {
        name  = "OPENAI_APIKEY"
        value = var.openai_apikey
      }
    }
    min_replicas = 1
    max_replicas = 3
  }
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "http"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
      registry {
      server  = azurerm_container_registry.acr.login_server
      username = azurerm_container_registry.acr.admin_username
      password_secret_name = azurerm_container_registry.acr.admin_password
    }
  depends_on = [null_resource.run_azcli_script2]
}


# Script to push images to ACR
resource "null_resource" "run_azcli_script1" {
  provisioner "local-exec" {
    command = "az acr login --name ${azurerm_container_registry.acr.name} && az acr build --registry ${azurerm_container_registry.acr.name} --image careerapp:v30 ../frontend/smart-career"
  }
}

# Script to push images to ACR
resource "null_resource" "run_azcli_script2" {
  provisioner "local-exec" {
    command = "az acr login --name ${azurerm_container_registry.acr.name} && az acr build --registry ${azurerm_container_registry.acr.name} --image webapi:v30 ../backend/advicebackend"
  }

}