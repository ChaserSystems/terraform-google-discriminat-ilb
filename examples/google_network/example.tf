module "google_network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.1"

  network_name = "my-network"
  project_id   = "my-nevermind-123456"

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
