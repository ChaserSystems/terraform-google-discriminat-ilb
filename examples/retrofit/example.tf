module "discriminat" {
  source = "ChaserSystems/discriminat-ilb/google"

  subnetwork_name = "my-subnet"
  region          = "europe-west2"

  labels = {
    "x"   = "y"
    "foo" = "bar"
  }
}
