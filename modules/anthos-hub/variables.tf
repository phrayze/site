variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
}

variable "service_account_key_file" {
  description = "Path to service account key file to auth as for running `gcloud container clusters get-credentials`."
  default     = ""
}
