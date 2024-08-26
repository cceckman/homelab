
set -eu
redo-ifchange debian.img wlan0 wpa_supplicant.conf sysconf.txt

cp debian.img "$3"

if test -e ./mount
then
    sudo -n umount -Rd mount/ || true
    rm -rf ./mount
fi

mkdir -p mount/

# Set up mountpoint:
LODEV="$(sudo -n losetup --show -P -f "$3")"
sudo -n mount -o loop "$LODEV"p2 mount/
sudo -n mount -o loop "$LODEV"p1 mount/boot/firmware/

# Drop in files:
sudo -n mkdir -p mount/etc/wpa_supplicant/
cat wpa_supplicant.conf | sudo -n tee mount/etc/wpa_supplicant/wpa_supplicant.conf >/dev/null
cat wlan0 | sudo -n tee mount/etc/network/interfaces.d/wlan0 >/dev/null
cat sysconf.txt | sudo -n tee -a mount/boot/firmware/sysconf.txt >/dev/null

# Generate a random password for root:
echo "root_pw=$(head -c32 /dev/urandom | base64 | tr '=+' '@$')" \
|    sudo -n tee -a mount/boot/firmware/sysconf.txt >/dev/null

# Remove mountpoint (-R ecursive -d etach loop device)
sudo -n umount -Rd mount/
sync

echo >&2 "Baseline image ready"
