variable "project_id" {
  type        = string
  description = "The GCP Project ID for this deployment. For example: my-project-111222"
}

module "google_network" {
  source  = "terraform-google-modules/network/google"
  version = "> 3, < 12"

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

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }

  zones_names = ["europe-west2-a", "europe-west2-b"] # delete or set to [] for all zones

  # custom_service_account_email = "some-name@some-project.iam.gserviceaccount.com"

  preferences = <<EOF
  {
    "%default": {
      "flow_log_verbosity": "full",
      "see_thru": "2026-01-19"
    }
  }
  EOF

  depends_on = [module.google_network]
}

output "opt_out_network_tag" {
  value       = module.discriminat.opt_out_network_tag
  description = "The network tag for VMs needing to bypass DiscrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}

output "deployment_id" {
  value       = module.discriminat.deployment_id
  description = "The unique identifier, forming a part of various resource names, for this deployment."
}

output "default_preferences" {
  value       = module.discriminat.default_preferences
  description = "The default preferences supplied to DiscrimiNAT. See docs at https://chasersystems.com/docs/discriminat/gcp/default-prefs/"
}
