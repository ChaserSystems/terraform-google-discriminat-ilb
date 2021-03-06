# discrimiNAT, ILB architecture

[discrimiNAT firewall](https://chasersystems.com/discrimiNAT/) for egress filtering by FQDNs on Google Cloud. Just specify the allowed destination hostnames in the applications' native Firewall Rules and the firewall will take care of the rest.

**Architecture with internal TCP load balancers as next hops set as the default, and tag based opt-out control.**

[Demo Videos](https://chasersystems.com/discrimiNAT/demo/) | [discrimiNAT FAQ](https://chasersystems.com/discrimiNAT/faq/)

## Highlights

* Utilises Google's [Internal TCP/UDP load balancers as next hops](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview) technology.
* Provides rapid, seamless high-availability for the NAT and egress filtering function.
* The internal load balancer for discrimiNAT instances is set as the default route to the Internet for the entire VPC network.
* Opt-out of this default routing is possible by tagging the VMs with `bypass-discriminat` network tag.
* VMs _without_ public IPs will need firewall rules specifying what egress FQDNs and protocols are to be allowed. Default behaviour is to deny everything.

## Considerations

* Internal TCP/UDP load balancers as next hops [do not support network tags](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#additional_specifications) for routing specific, tagged instances through them.
* The default route is available to the entire VPC network, but a regional restriction is enforced. More on that [here](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#same_network_and_region).
* Only one deployment per network is advised.
* VMs _with_ public IPs will need the `bypass-discriminat` network tag in almost all cases.
* You must be subscribed to the [discrimiNAT firewall from the Google Cloud Marketplace](https://console.cloud.google.com/marketplace/details/chasersystems-public/discriminat?utm_source=gthb&utm_medium=dcs&utm_campaign=trrfrm).

## Next Steps

* [Understand how to configure the enhanced Firewall Rules](https://chasersystems.com/discrimiNAT/gcp/quick-start/#v-firewall-rules) after deployment from our main documentation.
* Contact our DevSecOps at devsecops@chasersystems.com for queries at any stage of your journey.

## Alternatives

* For an architecture with Network Tags in VPCs for fine-grained, opt-in control over routing, see the [NTag module](https://registry.terraform.io/modules/ChaserSystems/discriminat-ntag/google/).
