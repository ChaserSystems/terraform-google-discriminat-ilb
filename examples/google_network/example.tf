variable "project_id" {
  type        = string
  description = "The GCP Project ID for this deployment. For example: my-project-111222"
}

module "google_network" {
  source  = "terraform-google-modules/network/google"
  version = "> 3, < 4"

  network_name = "discriminat-example"
  project_id   = var.project_id

  subnets = [
    {
      subnet_name           = "subnet-foo"
      subnet_ip             = "192.168.101.0/24"
      subnet_region         = "europe-west2"
      subnet_private_access = true
    }
  ]
}

module "discriminat" {
  source = "ChaserSystems/discriminat-ilb/google"

  project_id      = var.project_id
  subnetwork_name = module.google_network.subnets["europe-west2/subnet-foo"].name
  region          = module.google_network.subnets["europe-west2/subnet-foo"].region

  client_cidrs = ["10.11.12.0/28"]

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }

  zones_names = ["europe-west2-a", "europe-west2-b"] # delete or set to [] for all zones

  depends_on = [module.google_network]
}

output "opt_out_network_tag" {
  value       = module.discriminat.opt_out_network_tag
  description = "The network tag for VMs needing to bypass discrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}

output "deployment_id" {
  value       = module.discriminat.deployment_id
  description = "The unique identifier, forming a part of various resource names, for this deployment."
}
