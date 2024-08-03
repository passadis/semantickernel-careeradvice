variable "azure_spsecret" {
  description = "SP"
  type        = string
}
variable "azure_clientid" {
  description = "AppID"
  type        = string
}

variable "azure_subid" {
  description = "Subscription ID"
  type        = string
}

variable "azure_tenantid" {
  description = "Tenant ID"
  type        = string
}

variable "openai_endpoint" {
  description = "Endpoint"
  type        = string
}
variable "openai_apikey" {
  description = "aPIKEY"
  type        = string
}
variable "pfx_password" {
  description = "PFX Password"
  type        = string
}