# discrimiNAT, ILB architecture

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
