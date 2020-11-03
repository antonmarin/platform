variable "google_service_account" {
  type        = string
  description = "JSON string of google service account key file used to access GCP"
}
variable "gcp_project" {
  type        = string
  description = "Project id of GoogleCloudPlatform project. Visit https://console.cloud.google.com/cloud-resource-manager"
}

variable "ssh_keys" {
  type        = map(string)
  description = "Map of users ssh-keys (user=key_content). Use HCL in Terraform Cloud"
}

variable "platform_apps" {
  type = map
  description = "Map of platform apps .env files (app_name=file_content). Use HCL in Terraform CLoud"
  default = {
    ingress = {
      app_name = "ingress"
      dot_env_file_content = "IS_WEB_UI_ENABLED=false"
    }
  }
}
