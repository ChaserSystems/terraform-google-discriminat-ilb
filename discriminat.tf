## Inputs

variable "subnetwork_name" {
  type        = string
  description = "The name of the subnetwork to deploy the discrimiNAT firewall instances in. This must already exist."
}

variable "region" {
  type        = string
  description = "The region the specified subnetwork is to be found in."
}

##

## Defaults

variable "zones_names" {
  type        = list(string)
  description = "Speficic zones if you wish to override the default behaviour. If not overridden, defaults to all zones found in the specified region."
  default     = []
}

variable "labels" {
  type        = map(any)
  description = "Map of key-value label pairs to apply to resources created by this module. See examples for use."
  default     = {}
}

variable "machine_type" {
  type        = string
  description = "The default of e2-small should suffice for light to medium levels of usage. Anything less than 2 CPU cores and 2 GB of RAM is not recommended. For faster access to the Internet and for projects with a large number of VMs, you may want to choose a machine type with more CPU cores."
  default     = "e2-small"
}

variable "instances_per_zone" {
  type        = number
  description = "This can be set to a higher number if deployment is single-zone only, to achieve rapid high-availability. For multi-zone deployments, a higher number will only spread the load across more instances."
  default     = 1
}

variable "block-project-ssh-keys" {
  type        = bool
  description = "Strongly suggested to leave this to the default, that is to NOT allow project-wide SSH keys to login into the firewall."
  default     = true
}

variable "startup_script_base64" {
  type        = string
  description = "Strongly suggested to NOT run custom, startup scripts on the firewall instances. But if you had to, supply a base64 encoded version here."
  default     = ""
}

##

## Lookups

data "google_compute_subnetwork" "context" {
  name   = var.subnetwork_name
  region = var.region
}

data "google_compute_zones" "auto" {
  region = var.region
}

data "google_compute_image" "discriminat" {
  name    = "discriminat-2-0-3"
  project = "chasersystems-public"
}

##

## Compute

resource "google_compute_instance_template" "discriminat" {
  name_prefix = "discriminat-${local.suffix}-"
  lifecycle {
    create_before_destroy = true
  }

  region = var.region

  tags           = ["discriminat-itself"]
  machine_type   = var.machine_type
  can_ip_forward = true

  metadata_startup_script = var.startup_script_base64 == "" ? null : base64decode(var.startup_script_base64)

  metadata = {
    block-project-ssh-keys = var.block-project-ssh-keys
  }

  disk {
    source_image = data.google_compute_image.discriminat.self_link
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnetwork_name

    access_config {
    }
  }

  service_account {
    scopes = ["compute-ro", "logging-write", "monitoring-write"]
  }

  labels = local.labels
}

resource "google_compute_health_check" "discriminat" {
  name = "discriminat-${local.suffix}"

  healthy_threshold   = 2
  unhealthy_threshold = 2
  check_interval_sec  = 2
  timeout_sec         = 2

  http_health_check {
    port = 1042
  }
}

resource "google_compute_region_instance_group_manager" "discriminat" {
  name                      = "discriminat-${local.suffix}"
  base_instance_name        = "discriminat"
  distribution_policy_zones = local.zones
  target_size               = length(local.zones) * var.instances_per_zone

  region = var.region

  wait_for_instances = true

  version {
    instance_template = google_compute_instance_template.discriminat.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.discriminat.id
    initial_delay_sec = 120
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = length(local.zones)
    max_unavailable_fixed        = 0
  }
}

resource "google_compute_region_backend_service" "discriminat" {
  name = "discriminat-${local.suffix}"

  region = var.region

  load_balancing_scheme = "INTERNAL"
  protocol              = "TCP"
  network               = data.google_compute_subnetwork.context.network

  connection_draining_timeout_sec = 60

  backend {
    group = google_compute_region_instance_group_manager.discriminat.instance_group
  }

  health_checks = [google_compute_health_check.discriminat.id]
}

resource "google_compute_forwarding_rule" "discriminat" {
  name = "discriminat-${local.suffix}"

  region = var.region

  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  all_ports             = true
  subnetwork            = var.subnetwork_name

  backend_service = google_compute_region_backend_service.discriminat.id
}

##

## VPC

resource "google_compute_route" "discriminat" {
  name         = "discriminat-${local.suffix}"
  dest_range   = "0.0.0.0/0"
  network      = data.google_compute_subnetwork.context.network
  next_hop_ilb = google_compute_forwarding_rule.discriminat.id
  priority     = 200
}

resource "google_compute_route" "bypass_discriminat" {
  name             = "bypass-discriminat-${local.suffix}"
  tags             = ["bypass-discriminat", "discriminat-itself"]
  dest_range       = "0.0.0.0/0"
  network          = data.google_compute_subnetwork.context.network
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

resource "google_compute_firewall" "discriminat-to-internet" {
  name    = "discriminat-${local.suffix}-to-internet"
  network = data.google_compute_subnetwork.context.network

  direction = "EGRESS"
  priority  = 200

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["discriminat-itself"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "discriminat-from-healthcheckers" {
  name    = "discriminat-${local.suffix}-from-healthcheckers"
  network = data.google_compute_subnetwork.context.network

  direction = "INGRESS"
  priority  = 200

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["discriminat-itself"]

  allow {
    protocol = "tcp"
    ports    = [1042]
  }
}

resource "google_compute_firewall" "discriminat-from-clients" {
  name    = "discriminat-${local.suffix}-from-clients"
  network = data.google_compute_subnetwork.context.network

  direction = "INGRESS"
  priority  = 200

  target_tags   = ["discriminat-itself"]
  source_ranges = [data.google_compute_subnetwork.context.ip_cidr_range]

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "discriminat-from-rest" {
  name    = "discriminat-${local.suffix}-from-rest"
  network = data.google_compute_subnetwork.context.network

  direction = "INGRESS"
  priority  = 400

  target_tags   = ["discriminat-itself"]
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

##

## Locals

locals {
  suffix = replace("${var.region}${var.subnetwork_name}", "/[aeiou-]/", "")
}

locals {
  labels = merge(
    {
      "product" : "discriminat",
      "vendor" : "chasersystems_com"
    },
    var.labels
  )
}

locals {
  zones = length(var.zones_names) > 0 ? var.zones_names : data.google_compute_zones.auto.names
}

##

## Outputs

output "opt_out_network_tag" {
  value       = "bypass-discriminat"
  description = "The network tag for VMs needing to bypass discrimiNAT completely."
}

##
