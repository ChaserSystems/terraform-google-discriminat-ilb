module "google_network" {
  source  = "terraform-google-modules/network/google"
  version = "> 3, < 4"

  network_name = "my-network"
  project_id   = "my-project-123456"

  subnets = [
    {
      subnet_name   = "my-subnet"
      subnet_ip     = "192.168.101.0/24"
      subnet_region = "europe-west2"
    }
  ]
}

module "discriminat" {
  for_each = module.google_network.subnets

  source = "ChaserSystems/discriminat-ilb/google"

  subnetwork_name = each.value.name
  region          = each.value.region

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }

  depends_on = [module.google_network]
}

output "opt_out_network_tag" {
  value       = module.discriminat["europe-west2/my-subnet"].opt_out_network_tag
  description = "The network tag for VMs needing to bypass discrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}

output "deployment_id" {
  value       = module.discriminat["europe-west2/my-subnet"].deployment_id
  description = "The unique identifier, forming a part of various resource names, for this deployment."
}
