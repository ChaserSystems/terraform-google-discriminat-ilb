variable "project_id" {
  type        = string
  description = "The GCP Project ID for this deployment. For example: my-project-111222"
}

module "discriminat" {
  source = "ChaserSystems/discriminat-ilb/google"

  project_id      = var.project_id
  subnetwork_name = "my-subnetwork"
  region          = "europe-west2"

  client_cidrs = ["10.11.12.0/28"]

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }
}

output "opt_out_network_tag" {
  value       = module.discriminat.opt_out_network_tag
  description = "The network tag for VMs needing to bypass discrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}
