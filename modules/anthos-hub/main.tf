resource "google_project_service_identity" "hub_sa" {
  provider = google-beta

  project = var.project_id
  service = "gkehub.googleapis.com"
}

resource "google_project_iam_member" "hub_sa_serviceAgent" {
  project = var.project_id
  role    = "roles/gkehub.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.hub_sa.email}"
}

module "enable_acm" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 2.0"

  platform              = "linux"
  upgrade               = true
  additional_components = ["alpha"]

  service_account_key_file = var.service_account_key_file
  create_cmd_entrypoint    = "gcloud"
  create_cmd_body          = "alpha container hub config-management enable --project ${var.project_id}"
  destroy_cmd_entrypoint   = "gcloud"
  destroy_cmd_body         = "alpha container hub config-management disable --force --project ${var.project_id}"
}

resource "google_sourcerepo_repository" "acm-config-prod" {
  project = var.project_id
  name    = "anthos-config-prod"
}
