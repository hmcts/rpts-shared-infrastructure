
variable "common_tags" {
  type = map(string)
}

variable "product" {
  default = "rpts"
}
variable "env" {}
variable "tenant_id" {}

variable "location" {
  default = "UK South"
}

variable "managed_identity_object_id" {
  default = map("")
}

variable "jenkins_AAD_objectId" {
  description = "(Required) The Azure AD object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies."
}

variable "appinsights_location" {
  default     = "West Europe"
  description = "Location for Application Insights"
}
