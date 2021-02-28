# discrimiNAT, ILB architecture, retrofit example

Demonstrates how to retrofit discrimiNAT egress filtering in a pre-existing VPC subnetwork, for a chosen region.

## Example

See file `example.tf` in the _Source Code_ link above.

## Considerations

1. The subnetwork must already exist, otherwise the module will fail with `The argument "network" is required, but no definition was found.` errors.
