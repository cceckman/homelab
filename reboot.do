
set -eux

# TODO: Get targets from nix eval
for target in rack4
do
  ssh "$target" 'sudo reboot'
done

