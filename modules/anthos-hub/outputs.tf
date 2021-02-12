output "anthos_hub_sa" {
  value = google_project_service_identity.hub_sa.email
}
