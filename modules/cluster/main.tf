data "google_client_config" "default" {}

resource "random_id" "postfix" {
  byte_length = 4
}

resource "google_project_iam_member" "hub_sa_serviceAgent" {
  project = var.project_id
  role    = "roles/gkehub.serviceAgent"
  member  = "serviceAccount:${var.anthos_hub_sa}"
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "${var.name}-gke-${random_id.postfix.hex}"
  display_name = "${var.name}-gke-${random_id.postfix.hex}"
}

resource "google_project_iam_member" "service_account_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "compute_security_admin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_admin" {
  project = var.project_id
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = var.name
  regional                   = true
  region                     = var.region
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  create_service_account     = false
  service_account            = google_service_account.service_account.email
  enable_private_endpoint    = "false"
  enable_private_nodes       = "true"
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  default_max_pods_per_node  = 110
  remove_default_node_pool   = true
  add_cluster_firewall_rules = true

  node_pools = [
    {
      name              = "${var.name}-np-01"
      min_count         = 1
      max_count         = 100
      local_ssd_count   = 0
      disk_size_gb      = 100
      disk_type         = "pd-standard"
      machine_type      = "e2-standard-4"
      image_type        = "COS"
      auto_repair       = true
      auto_upgrade      = true
      service_account   = google_service_account.service_account.email
      preemptible       = false
      max_pods_per_node = 12
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = var.authorized_network_cidr_block
      display_name = "VPC"
    },
  ]
}

module "asm" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"

  project_id       = var.project_id
  cluster_name     = module.gke.name
  location         = module.gke.location
  cluster_endpoint = module.gke.endpoint
}

module "acm" {
  source           = "terraform-google-modules/kubernetes-engine/google///modules/acm"
  project_id       = var.project_id
  location         = module.gke.location
  cluster_name     = module.gke.name
  sync_repo        = var.acm_sync_repo
  sync_branch      = var.acm_sync_branch
  policy_dir       = var.acm_policy_dir
  cluster_endpoint = module.gke.endpoint
}
