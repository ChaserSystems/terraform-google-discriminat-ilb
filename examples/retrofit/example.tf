variable "project_id" {
  type        = string
  description = "The GCP Project ID for this deployment. For example: my-project-111222"
}

module "discriminat" {
  source = "ChaserSystems/discriminat-ilb/google"

  project_id      = var.project_id
  subnetwork_name = "my-subnetwork"
  region          = "europe-west2"

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }

  # custom_service_account_email = "some-name@some-project.iam.gserviceaccount.com"

  # preferences = <<EOF
  # {
  #   "%default": {
  #     "flow_log_verbosity": "only_disallowed"
  #   }
  # }
  #   EOF
}

output "opt_out_network_tag" {
  value       = module.discriminat.opt_out_network_tag
  description = "The network tag for VMs needing to bypass DiscrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}

output "default_preferences" {
  value       = module.discriminat.default_preferences
  description = "The default preferences supplied to DiscrimiNAT. See docs at https://chasersystems.com/docs/discriminat/gcp/default-prefs/"
}
