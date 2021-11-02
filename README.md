# discrimiNAT, ILB architecture

[discrimiNAT firewall](https://chasersystems.com/discrimiNAT/) for egress filtering by FQDNs on Google Cloud. Just specify the allowed destination hostnames in the respective applications' native Firewall Rules and the firewall will take care of the rest.

![](https://chasersystems.com/media/gcp-protocol-tls.gif)

**Architecture with internal TCP load balancers as next hops set as the default, and tag based opt-out control.**

[Demo Videos](https://chasersystems.com/discrimiNAT/demo/) | [discrimiNAT FAQ](https://chasersystems.com/discrimiNAT/faq/)

## Pentest Ready

discrimiNAT enforces the use of contemporary encryption standards such as TLS 1.2+ and SSH v2 with bidirectional in-band checks. Anything older or insecure will be denied connection automatically. Also conducts out-of-band checks, such as DNS, for robust defence against sophisticated malware and insider threats. Gets your VPC ready for a proper pentest!

## Highlights

* Utilises Google's [Internal TCP/UDP load balancers as next hops](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview) technology.
* Provides rapid, seamless high-availability for the NAT and egress filtering function.
* The internal load balancer for discrimiNAT instances is set as the default route to the Internet for the entire VPC network.
* Opt-out of this default routing is possible by tagging the VMs with `bypass-discriminat` network tag.
* VMs _without_ public IPs will need firewall rules specifying what egress FQDNs and protocols are to be allowed. Default behaviour is to deny everything.

## Considerations

* ~~Internal TCP/UDP load balancers as next hops [do not support network tags](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#additional_specifications) for routing specific, tagged instances through them.~~ Tag support for Internal TCP/UDP load balancers as next hops is now in [Preview](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#additional_considerations), covered by the Pre-GA Offerings Terms of the Google Cloud Terms of Service. This module will be updated in due course to support it.
* The default route is available to the entire VPC network, but a regional restriction is enforced. More on that [here](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#same_network_and_region).
* Only one deployment per network is advised, and GCP-managed Cloud NAT is not needed with discrimiNAT deployed.
* VMs _with_ public IPs will need the `bypass-discriminat` network tag in almost all cases.
* You must be subscribed to the [discrimiNAT firewall from the Google Cloud Marketplace](https://console.cloud.google.com/marketplace/details/chasersystems-public/discriminat?utm_source=gthb&utm_medium=dcs&utm_campaign=trrfrm).

## Alternatives

* For an architecture with Network Tags in VPCs for fine-grained, opt-in control over routing, see the [NTag module](https://registry.terraform.io/modules/ChaserSystems/discriminat-ntag/google/).

## Next Steps

* [Understand how to configure the enhanced Firewall Rules](https://chasersystems.com/discrimiNAT/gcp/config-ref/) after deployment from our main documentation.
* If using **Shared VPCs**, read [our guide](https://chasersystems.com/discrimiNAT/gcp/shared-vpc/) on creating and overriding the service account needed for it.
* Contact our DevSecOps at devsecops@chasersystems.com for queries at any stage of your journey – even on the eve of a pentest!

## Discover

Perhaps use the `see-thru` mode to discover what needs to be in the allowlist for an application, by monitoring its outbound network activity first. Follow our [building an allowlist from scratch](https://chasersystems.com/discrimiNAT/gcp/logs-ref/#building-an-allowlist-from-scratch) recipe for use with StackDriver.

![](https://chasersystems.com/media/gcp-see-thru.gif)

## Post-deployment Firewall Rule Example

```hcl
# These Firewall Rules must be associated with their intended, respective applications.
resource "google_compute_firewall" "logging_google" {
  name = "logging-google"

  # You could use a data source or get a reference from another resource for the Network name.
  network = "default"

  direction = "EGRESS"

  # Tags of instances this Rule applies to, as usual.
  target_tags = ["foo"]

  # The discrimiNAT firewall will apply its own checks anyway, so you could
  # choose to leave destination_ranges not defined without worry.
  # destination_ranges =

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # You could simply embed an allowed FQDN, like below.
  # Full syntax at https://chasersystems.com/discrimiNAT/gcp/quick-start/#v-firewall-rules
  description = "discriminat:tls:logging.googleapis.com"
}

resource "google_compute_firewall" "saas_monitoring" {
  name    = "saas-monitoring"
  network = "default"

  direction   = "EGRESS"
  target_tags = ["foo"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Or you could embed a few allowed FQDNs, comma-separated, like below.
  # Full syntax at https://chasersystems.com/discrimiNAT/gcp/quick-start/#v-firewall-rules
  description = "discriminat:tls:app.datadoghq.com,collector.newrelic.com"
}

locals {
  # Or you could store allowed FQDNs as a list...
  fqdns_sftp_banks = [
    "sftp.bank1.com",
    "sftp.bank2.com"
  ]
  fqdns_saas_auth = [
    "foo.auth0.com",
    "mtls.okta.com"
  ]
}

locals {
  # ...and format them into the expected syntax.
  discriminat_sftp_banks = format("discriminat:ssh:%s", join(",", local.fqdns_sftp_banks))
  discriminat_saas_auth  = format("discriminat:tls:%s", join(",", local.fqdns_saas_auth))
}

resource "google_compute_firewall" "saas_auth" {
  name    = "saas-auth"
  network = "default"

  direction   = "EGRESS"
  target_tags = ["foo"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Use of FQDNs list formatted into the expected syntax.
  description = local.discriminat_saas_auth
}

resource "google_compute_firewall" "sftp_banks" {
  name    = "sftp-banks"
  network = "default"

  direction   = "EGRESS"
  target_tags = ["foo"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Use of FQDNs list formatted into the expected syntax.
  description = local.discriminat_sftp_banks
}
```
