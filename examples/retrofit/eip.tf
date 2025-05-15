resource "google_compute_address" "nat_a" {
  name = "static-egress-ip-a"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # Set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # deployment of DiscrimiNAT is desired. Some (any) value must be present otherwise.
    "discriminat" = "some-comment_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_address" "nat_b" {
  name = "static-egress-ip-b"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # Set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # deployment of DiscrimiNAT is desired. Some (any) value must be present otherwise.
    "discriminat" = "any-remark_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_address" "nat_c" {
  name = "static-egress-ip-c"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # Set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # deployment of DiscrimiNAT is desired. Some (any) value must be present otherwise.
    "discriminat" = "whatsoever_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}
