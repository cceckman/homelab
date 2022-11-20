# Old NixOS configs

These are NixOS configs I used from my first attempt to use NixOS for the
homelab. Notes included below; SHA references are to github.com/cceckman/imager.

# Worklog


NixOS configs for Morph

Cribbed wholesale from Xe Iaso's post
[here](https://xeiaso.net/blog/morph-setup-2021-04-25) - thanks for the great
resource, Xe!

## Attempt 1

Instead of trying to build an image from scratch - which _should_ be trivial
under Nix, but is apparently not entirely so - we're going to start with the
stock image, and then patch it with [Morph](https://github.com/DBCDK/morph) to
match our intended configuration.

Since we're managing a bunch of RPis, for the most part, this is probably
fine.

### Results

It was Not Fine.

The default image allows login via TTY - auto-login, in fact, as the
passwordless `nixos` user.

But SSH login appears unavailable, as `root` or `nixos`. So we _do_ need to
build the image and pivot.

The weird thing is that... in none of these images does there appear to be a
`configuration.nix` file? There's clearly some sort of state managed by NixOS,
users and groups and whatnot - in particular, what I've specified in my
image-making config... but it doesn't appear to show up in the built image?
Maybe it's under something that I'm not seeing.

## Attempt 2

Starting with 7041bcd - I'll use my `pi3.img` target to prepopulate 'root',
then go from there. I think this involves writing `configuration.nix` in the
Morph tree and uploading it...?

### Results

Well, had to do some more tweaks from that commit; see...whatever commit gets
this message, to see what they are.

After that build, I flashed the image, and...I can log in, as myself! Not as
`root`, though, for whatever reason. Eh, maybe it'll still work.

## Continued attempts

This is still not working well. Various sorts of build errors- AFAICT, coming
from graphical (!) JRE dependencies that Airsonic / Subsonic pull in. And no, I
don't know why they aren't just coming from the binary cache...

The errors I've seen:

- With a non-minimal JRE dependency, crossbuild fails (for... `libidl`?)
  The build of the package wants to execute tests, but it "cannot execute tests
  during cross-compilation" (or a semantically similar message)
- With a minimal JRE dependency, crossbuild fails with an error from the
  auto-patch-ELF (?) script - a NixOS thing - due to a missing library.

And finally, for whatever reason - enabling `/mnt/mediahd` seems to bork SSH
connectivity. Wha?

All this to say I'm somewhat unsatisfied with the Morph flow in this respect-
which may be the same as NixOps, more or less? Apparently Nix builds are not
reproducible across systems...

I'm wondering if there's a different viable approach...

- The top-level config file specifies: "Here are my hosts, here is the path of
  the `configuration.nix` for each"
- The controller copies the whole config tree to
  `/etc/nixos/configuration.nix.d/...` on each host - and fills
  `/etc/nixos/configuration.nix` with an import of to the `configuration.nix`
  for each
- The controller triggers some sort of `nixos-rebuild` on each
  - I'd like to be work-conserving, and avoid rebuilding the same dependency on
    each. Maybe that's best served by having then point to the same set of
    remote builders - so if / when a build is needed, it's that server's
    responsibility to queue / deduplicate correctly - rather than the
    controller's responsibility.
  - So: "just" trigger `nixos-rebuild`, concurrent on all.
- The controller serially triggers switch and performs healthchecks

## Baby steps

In the mean time - probably the right thing to do to "get things working" is to
treat these as pets. Have scripts to copy up the `nixos-configs` tree and
trigger the rebuild; and manually put in the `import` statements per-node to
define where it goes.

Trying that - I still run in to a key issue.

> Note: You can sudo nix-channel --remove nixpkgs, but you still need a
> nix-channel for nixos
>
>   sudo nix-channel --list
>   nixos https://nixos.org/channels/nixos-21.05
>

- [Pinnin nixpkgs](https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs)

That is... my build isn't hermetic, no matter what I do! WTF!
I still have an implicit dependency on "what nixos channel I'm on and where it
is".

Maybe [this is solved with
flakes](https://discourse.nixos.org/t/how-to-pin-nix-registry-nixpkgs-to-release-channel/14883/5)?
I guess I'm going to have to relearn everything with flakes?

But maybe Nix is just kinda crap. Every single 22.05 build in the history has
had "eval errors" and failing builds - that is, reproducible "this doesn't
work"-iness.
