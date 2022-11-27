# Worklog

## Episode 1: Parity

First thing's first: build a provisioning image, as an SD card, for Raspberry
Pis.

I had this working before, roughly, though it seemed a little unstable _after_
provisioning - since the effective `configuration.nix` file used to build the
image wasn't on the output. Flakes might make this a little more stable.

I had tried to do something a little fancier, but settled from porting [this
post by Ana, Hoverbear][hoverbear] to the SD image version, and adding the
SSH-able mixin.

I'm still missing one bit: how to make my local (non-NixOS, x86_64) builder
build the aarch64 target image. I have a remote builder set up that will accept
crossbuild, but for this kind of thing (mostly just composing artifacts from the
cache) I should be able to do it locally.

Maybe it's time for me to set up a local NixOS VM... Or, once I have a NixOS Pi,
use that for builds.

[hoverbear]: https://hoverbear.org/blog/nix-flake-live-media/

## Episode 2: Upgradeability

As of 9e4ba033, we have a working provisioning-image builder; I can log in to a
Pi that boots from that image. Now the tricky bit- pivoting that to "maintaining Nix on a running system".

Is it that tricky, though? We do have the [Tweag] guide to help us. We've set
the "provisioning" image to be its own configuration; maybe this is "just"
a matter of deploying another configuration stanza, rather than having a whole
new $something. Let's try it out.

[Tweag]: https://www.tweag.io/blog/2020-07-31-nixos-flakes/

I'd like to be able to do `nixos-rebuild --target-host`, but it
[looks like that won't cross-compile][issue166838]... unless we're careful
about [setting `crossSystem`][issue167393] correctly. Let's try that?

[issue166838]: https://github.com/NixOS/nixpkgs/issues/166838
[issue167393]: https://github.com/NixOS/nixpkgs/pull/167393/files

### Intermediate results

Specifying `system.configurationRevision` per [this guide][Tweag] didn't work well-

```
∵ nix flake check --show-trace
warning: Git tree '/home/cceckman/r/github.com/cceckman/homelab' is dirty
error: attribute 'system.configurationRevision' already defined at /nix/store/bsgikzgvk506r7sjplhrqv23w1spfa79-source/flake.nix:11:9

       at /nix/store/bsgikzgvk506r7sjplhrqv23w1spfa79-source/flake.nix:12:9:
```

But that's because I got it wrong- I had `system.configurationRevision` in the
`nixosSystem` arguments, when it needs to be defined in a module.
That wound up as `common/version.nix`

### More intermediate results

I tried using `--target-host` and `crossSystem`:

```
nixpkgs.crossSystem.system = "aarch64-linux"
```

- which did appear to start up builds, but then failed to compile anything.
I'm going to try to use `--build-host` to target the build on the target machine;
with `nixpkgs` at the same version, maybe that will mean we still get lots from cache?

### Yet more intermediate results

`--build-host` appears to have no effect. [This thread](https://discourse.nixos.org/t/building-a-flake-based-nixos-system-remotely/11309/2) referes to the wiki for
"remote builds with flakes appear to be broken". [This](https://github.com/NixOS/nixpkgs/pull/119540)
is supposed to fix it... am I using that?

So, is there a sensible way I can make my local (non-NixOS) machine crossbuild-enabled?

What goes wrong when:

- No `crossSystem`, no `--build-host`:
  - `build` is missing an `aarch64` host
  - `switch` gets `exec format error`
- No `crossSystem`, `--target-host` and `--build-host` match
  - `build` exits with status 0
  - `switch` gets exec format error (from `mktemp`)
- `crossSystem` is `lib.systems.examples.aarch64-multiplatform`; `--target-host` and `--build-host` match
  - `build` runs for a while; `nix-store` on the remote eats time


In all of the above:
- no remote builders configured.
- Flags precede verb (`nixos-reconfigure --target-host ... build`)
