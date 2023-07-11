## Inputs

variable "project_id" {
  type        = string
  description = "The GCP Project ID for this deployment. For example: my-project-111222"
}

variable "subnetwork_name" {
  type        = string
  description = "The name of the subnetwork to deploy the DiscrimiNAT Firewall instances in. This must already exist."
}

variable "region" {
  type        = string
  description = "The region the specified subnetwork is to be found in."
}

##

## Defaults

variable "zones_names" {
  type        = list(string)
  description = "Specific zones if you wish to override the default behaviour. If not overridden, defaults to all zones found in the specified region."
  default     = []
}

variable "only_route_tags" {
  type        = list(string)
  description = "Restrict automatically created default route (to the Internet) to VMs with these network tags only. Especially useful in the case of multiple, distinct DiscrimiNAT deployments in the same VPC Network, where each deployment caters to a subset of VMs in that network. For example, a VPC Network may span multiple regions and the default route for each region must be scoped to the DiscrimiNAT deployment of the same region. Default is to route all traffic regardless of any criteria via this deployment – which may clash with another such deployment's default route, and route egress traffic in a deterministic but most likely via a suboptimal gateway (DiscrimiNAT)."
  default     = null
}

variable "client_cidrs" {
  type        = list(string)
  description = "Additional CIDR blocks of clients which should be able to connect to, and hence route via, DiscrimiNAT instances. Defaults to RFC1918 ranges."
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "labels" {
  type        = map(any)
  description = "Map of key-value label pairs to apply to resources created by this module. See examples for use."
  default     = {}
}

variable "custom_deployment_id" {
  type        = string
  description = "Override the randomly generated Deployment ID for this deployment. This is a unique identifier for this deployment that may help with naming, labelling and associating other objects (such as External IPs) to only this set of DiscrimiNAT instances – earmarking from other, parallel deployments."
  default     = null
}

variable "machine_type" {
  type        = string
  description = "The default of `e2-small` should suffice for light to medium levels of usage. Anything less than 2 CPU cores and 2 GB of RAM is not recommended. For faster access to the Internet and for projects with a large number of VMs, you may want to upgrade to `n2-highcpu-2` or `n2d-highcpu-2`."
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
  default     = null
}

variable "custom_service_account_email" {
  type        = string
  description = "Override with a specific, custom service account email in case support for architectures with Shared VPC and/or Serverless VPC Access is needed. Default is to use the Google Compute Engine service account."
  default     = null
}

variable "image_project" {
  type        = string
  description = "Reserved for use with Chaser support. Allows overriding the source image project for DiscrimiNAT."
  default     = null
}

variable "image_family" {
  type        = string
  description = "Reserved for use with Chaser support. Allows overriding the source image version for DiscrimiNAT."
  default     = null
}

##

## Lookups

data "google_compute_subnetwork" "context" {
  name    = var.subnetwork_name
  region  = var.region
  project = var.project_id
}

data "google_compute_zones" "auto" {
  region  = var.region
  project = var.project_id
}

data "google_compute_image" "discriminat" {
  family  = var.image_family == null ? "discriminat" : var.image_family
  project = var.image_project == null ? "chasersystems-public" : var.image_project
}

##

## Compute

resource "google_compute_instance_template" "discriminat" {
  name_prefix = "discriminat-${local.suffix}-"
  lifecycle {
    create_before_destroy = true
  }

  region  = var.region
  project = var.project_id

  tags           = ["discriminat-itself"]
  machine_type   = var.machine_type
  can_ip_forward = true

  metadata_startup_script = var.startup_script_base64 == null ? null : base64decode(var.startup_script_base64)

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
    subnetwork         = var.subnetwork_name
    subnetwork_project = var.project_id
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = var.custom_service_account_email
    scopes = var.custom_service_account_email == null ? ["compute-rw", "logging-write", "monitoring-write"] : ["cloud-platform"]
  }

  labels = local.labels
}

resource "google_compute_health_check" "discriminat" {
  name = "discriminat-${local.suffix}"

  project = var.project_id

  healthy_threshold   = 2
  unhealthy_threshold = 2
  check_interval_sec  = 2
  timeout_sec         = 2

  http_health_check {
    port = 1042
  }

  depends_on = [google_compute_firewall.discriminat-from-healthcheckers]
}

resource "google_compute_region_instance_group_manager" "discriminat" {
  name                      = "discriminat-${local.suffix}"
  base_instance_name        = "discriminat-${local.suffix}"
  distribution_policy_zones = local.zones
  target_size               = length(local.zones) * var.instances_per_zone

  region  = var.region
  project = var.project_id

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

  region  = var.region
  project = var.project_id

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

  region  = var.region
  project = var.project_id

  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  all_ports             = true
  subnetwork            = var.subnetwork_name

  backend_service = google_compute_region_backend_service.discriminat.id
}

##

## VPC

resource "google_compute_route" "discriminat" {
  name    = "discriminat-${local.suffix}"
  project = var.project_id

  dest_range   = "0.0.0.0/0"
  network      = data.google_compute_subnetwork.context.network
  next_hop_ilb = google_compute_forwarding_rule.discriminat.id
  priority     = 200

  tags = var.only_route_tags
}

resource "google_compute_route" "bypass_discriminat" {
  name    = "bypass-discriminat-${local.suffix}"
  project = var.project_id

  tags             = ["bypass-discriminat", "discriminat-itself"]
  dest_range       = "0.0.0.0/0"
  network          = data.google_compute_subnetwork.context.network
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

resource "google_compute_firewall" "discriminat-to-internet" {
  name    = "discriminat-${local.suffix}-to-internet"
  project = var.project_id

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
  project = var.project_id

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
  project = var.project_id

  network = data.google_compute_subnetwork.context.network

  direction = "INGRESS"
  priority  = 200

  target_tags   = ["discriminat-itself"]
  source_ranges = concat([data.google_compute_subnetwork.context.ip_cidr_range], var.client_cidrs)

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "discriminat-from-rest" {
  name    = "discriminat-${local.suffix}-from-rest"
  project = var.project_id

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

resource "random_pet" "deployment_id" {
  keepers = {
    region          = var.region
    subnetwork_name = var.subnetwork_name
  }
  length = 1
}

locals {
  suffix = var.custom_deployment_id != null ? var.custom_deployment_id : random_pet.deployment_id.id
}

locals {
  labels = merge(
    {
      "product" : "discriminat",
      "vendor" : "chasersystems_com",
      "discriminat" : local.suffix
    },
    var.labels
  )
}

locals {
  zones = length(var.zones_names) > 0 ? var.zones_names : data.google_compute_zones.auto.names
}

##

## Constraints

terraform {
  required_version = "> 1, < 2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "> 3, < 5"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "> 3, < 5"
    }
  }
}

##

## Outputs

output "opt_out_network_tag" {
  value       = "bypass-discriminat"
  description = "The network tag for VMs needing to bypass DiscrimiNAT completely, such as bastion hosts. Such VMs should also have a Public IP."
}

output "deployment_id" {
  value       = local.suffix
  description = "The unique identifier, forming a part of various resource names, for this deployment."
}

##
