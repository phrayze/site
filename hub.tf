/******************************************
  Project for Anthos Hub
*****************************************/

module "anthos_hub_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 8.0"
  random_project_id           = "true"
  impersonate_service_account = var.terraform_service_account
  default_service_account     = "deprivilege"
  name                        = "anthos-hub"
  org_id                      = var.org_id
  billing_account             = var.billing_account
  folder_id                   = var.folder_id
  skip_gcloud_download        = var.skip_gcloud_download

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "anthos.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "billingbudgets.googleapis.com",
    "sourcerepo.googleapis.com",
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

module "anthos_hub" {
  source     = "./modules/anthos-hub"
  project_id = module.anthos_hub_project.project_id
}
