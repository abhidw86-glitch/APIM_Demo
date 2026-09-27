variable "project_name" {
  description = "Short project identifier used in Azure resource names."
  type        = string
  default     = "apim-security-demo"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "indiasouthcentral"
}

variable "resource_group_name" {
  description = "Resource group for the demo resources."
  type        = string
  default     = "rg-apim-security-demo"
}

variable "apim_name" {
  description = "Globally unique, 1-50 character APIM service name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,50}$", var.apim_name))
    error_message = "apim_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "publisher_name" {
  description = "Publisher name shown by API Management."
  type        = string
  default     = "Contoso Security Engineering"
}

variable "publisher_email" {
  description = "Publisher email required by API Management."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.publisher_email))
    error_message = "publisher_email must be a valid email address."
  }
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}