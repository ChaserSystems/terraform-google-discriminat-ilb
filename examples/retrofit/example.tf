module "discriminat" {
  source = "ChaserSystems/discriminat-ilb/google"

  subnetwork_name = "my-subnet"
  region          = "europe-west2"

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }
}

output "opt_out_network_tag" {
  value       = module.discriminat.opt_out_network_tag
  description = "The network tag for VMs needing to bypass discrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}
