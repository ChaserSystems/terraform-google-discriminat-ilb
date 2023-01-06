resource "google_compute_address" "nat_a" {
  provider = google-beta

  name = "static-egress-ip-a"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # fleet of DiscrimiNAT's is desired
    "discriminat" = "some-comment_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_address" "nat_b" {
  provider = google-beta

  name = "static-egress-ip-b"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # fleet of DiscrimiNAT's is desired
    "discriminat" = "any-remark_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_address" "nat_c" {
  provider = google-beta

  name = "static-egress-ip-c"

  address_type = "EXTERNAL"

  region  = "europe-west2"
  project = var.project_id

  labels = {
    # set the value of label 'discriminat' to custom_deployment_id as passed to
    # the discriminat module if pinning this External IP to that particular
    # fleet of DiscrimiNAT's is desired
    "discriminat" = "whatsoever_or_custom-deployment-id"
  }

  lifecycle {
    prevent_destroy = false
  }
}
