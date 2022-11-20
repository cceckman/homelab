# homelab
Configuration and build for homelab machines.

Many of the files here were ported from my `imager` repository; it wound up with
a number of things I didn't need any more, so this represents the more-or-less
clean history starting from getting Nix working.

## Configuration flow

The `provisioning/` directory contains materials for "provisioning" images-
unqualified / uncustomized other than to become reachable via SSH (with a set of
my keys). For instance,
the first `provisioning` target is an SD card image for Raspberry Pis.

From there, we use a combination of scripts and tools to manage nodes.
I'm going to try using [Nix Flakes], as informed by [this guide][tweag] in part.

[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[tweag]: https://www.tweag.io/blog/2020-05-25-flakes/

