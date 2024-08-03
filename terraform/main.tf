# Create Randomness
resource "random_string" "str-name" {
  length  = 5
  upper   = false
  numeric = false
  lower   = true
  special = false
}
data "azurerm_client_config" "current" {}

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
  name                          = "azr${random_string.str-name.result}"
  resource_group_name           = azurerm_resource_group.rgdemo.name
  location                      = azurerm_resource_group.rgdemo.location
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = true
}

output "acrname" {
  value = azurerm_container_registry.acr.name
}


data "azurerm_container_registry" "acr" {
  name                = azurerm_container_registry.acr.name
  resource_group_name = azurerm_resource_group.rgdemo.name
}

# User Assigned Identity
resource "azurerm_user_assigned_identity" "uiserid" {
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
# Certificate
resource "azurerm_container_app_environment_certificate" "cert" {
  name                         = "azuredev"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  certificate_blob_base64      = filebase64("advicebackend.pfx")
  certificate_password         = "1q2w3e4r"
}


# Create Azure Container App - Frontend
resource "azurerm_container_app" "careerapp" {
  name                         = "careerapp"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  resource_group_name          = azurerm_resource_group.rgdemo.name
  revision_mode                = "Single"
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.uiserid.id
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uiserid.id]
  }
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

}

# Role Assignment
resource "azurerm_role_assignment" "acr1" {
  principal_id         = azurerm_user_assigned_identity.uiserid.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_resource_group.rgdemo.id
}


# Create Azure Container App - Backend
resource "azurerm_container_app" "webapi" {
  name                         = "webapi"
  container_app_environment_id = azurerm_container_app_environment.acaenv.id
  resource_group_name          = azurerm_resource_group.rgdemo.name
  revision_mode                = "Single"
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.uiserid.id
  }

  template {
    container {
      name   = "webapi"
      image  = "${azurerm_container_registry.acr.login_server}/webapi:v30"
      cpu    = 1
      memory = "2Gi"
      env {
        name  = "ALLOWED_ORIGINS"
        value = "https://xxxxxxxxxx.xxxxxxxxxx.xx"
      }
      env {
        name  = "OPENAI_API_ENDPOINT"
        value = var.openai_endpoint
      }
      env {
        name  = "OPENAI_API_KEY"
        value = var.openai_apikey
      }
	  env {
        name  = "PFX_PASSWORD"
        value = var.pfx_password
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
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uiserid.id]
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