/******************************************
  Project for Anthos Cluster 
*****************************************/
module "bu1-prod-app1" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 8.0"
  random_project_id           = "true"
  impersonate_service_account = var.terraform_service_account
  default_service_account     = "deprivilege"
  name                        = "bu1-p-app1"
  org_id                      = var.org_id
  billing_account             = var.billing_account
  folder_id                   = "folders/52355272450"
  skip_gcloud_download        = var.skip_gcloud_download

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "billingbudgets.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "gkehub.googleapis.com",
  ]

  labels = {
    environment       = "production"
    application_name  = "org-anthos-hub"
    billing_code      = "1234"
    primary_contact   = "example1"
    secondary_contact = "example2"
    business_code     = "abcd"
    env_code          = "p"
  }
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "v2.6.0"
  project_id   = module.bu1-prod-app1.project_id
  network_name = "bu1-app1-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "bu1-app1-euw1"
      subnet_ip             = "10.0.0.0/18"
      subnet_region         = "europe-west1"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    }
  ]

  secondary_ranges = {
    bu1-app1-euw1 = [
      {
        range_name    = "bu1-app1-cluster1-pods"
        ip_cidr_range = "10.1.0.0/24"
      },
      {
        range_name    = "bu1-app1-cluster1-svc"
        ip_cidr_range = "10.2.0.0/19"
      },
    ]
  }
}


module "anthos_cluster" {
  source                 = "./modules/cluster"
  project_id             = module.bu1-prod-app1.project_id
  name                   = "bu1-app1-cluster1"
  region                 = module.vpc.subnets_regions[0]
  network                = module.vpc.network_name
  subnetwork             = module.vpc.subnets_names[0]
  ip_range_services      = "bu1-app1-cluster1-svc"
  ip_range_pods          = "bu1-app1-cluster1-pods"
  master_ipv4_cidr_block = "192.168.0.0/28"
  #authorized_network_cidr_block = module.vpc.subnets_ips[0]
  #### ADDING FOR DEMO PURPOSES
  authorized_network_cidr_block = "0.0.0.0/0"
  ####
  #anthos_hub_project_id = var.anthos_hub_project_id
  #anthos_hub_sa         = var.anthos_hub_sa


  anthos_hub_project_id = module.anthos_hub_project.project_id
  anthos_hub_sa         = module.anthos_hub.anthos_hub_sa
  acm_sync_repo         = "ssh://gary@gcpgeek.cloud@source.developers.google.com:2022/p/anthos-hub-221b/r/anthos-config-prod"
  acm_sync_branch       = "master"
  acm_policy_dir        = "/prod"
}
