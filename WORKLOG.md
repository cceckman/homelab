# Worklog

## Episode 1: Parity

First thing's first: build a provisioning image, as an SD card, for Raspberry
Pis.

I had this working before, roughly, though it seemed a little unstable _after_
provisioning - since the effective `configuration.nix` file used to build the
image wasn't on the output. Flakes might make this a little more stable.

I had tried to do something a little fancier, but settled from porting
[this post by Ana, Hoverbear][hoverbear] to the SD image version, and adding the
SSH-able mixin.

I'm still missing one bit: how to make my local (non-NixOS, x86_64) builder
build the aarch64 target image. I have a remote builder set up that will accept
crossbuild, but for this kind of thing (mostly just composing artifacts from the
cache) I should be able to do it locally.

Maybe it's time for me to set up a local NixOS VM... Or, once I have a NixOS Pi,
use that for builds.

[hoverbear]: https://hoverbear.org/blog/nix-flake-live-media/
