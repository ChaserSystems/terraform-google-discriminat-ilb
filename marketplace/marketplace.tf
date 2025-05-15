resource "google_compute_address" "nat_a" {
  name = "static-egress-ip-a"

  address_type = "EXTERNAL"

  region  = var.region
  project = var.project_id

  labels = {
    # Set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # deployment of DiscrimiNAT is desired. Some (any) value must be present otherwise.
    "discriminat" = local.suffix
  }

  lifecycle {
    prevent_destroy = false
  }
}
