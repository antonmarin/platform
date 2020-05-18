variable "google_service_account" {
  type = string
  description = "JSON string of google service account key file used to access GCP"
}
variable "gcp_project" {
  type = string
  description = "Project id of GoogleCloudPlatform project. Visit https://console.cloud.google.com/cloud-resource-manager"
}
