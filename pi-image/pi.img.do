
set -eu

# Do the easily-interactive thing up front:
sudo -n echo >&2 "noninteractive sudo works"

# Put the decryption targets first, so we fail fast if we can't decrypt them.
# rpi-64.img is a big download if it's not already on disk, we don't want to download it and then get an error.
redo-ifchange tskey firstboot-wifi.sh rpi-64.img
chmod 0400 tskey

cp rpi-64.img "$3"

sudo -n "echo" >/dev/null || {
    echo >&2 "Need noninteractive sudo to complete, exiting"
    exit 1
}

if test -e ./mount
then
    sudo -n umount -Rd mount/ || true
    rm -rf ./mount
fi

mkdir -p mount/

# Set up mountpoint:
LODEV="$(sudo -n losetup --show -P -f "$3")"
sudo -n mount -o loop "$LODEV"p2 mount/
sudo -n mount -o loop "$LODEV"p1 mount/boot/

redo-ifchange userconf.txt firstboot.sh firstboot-wifi.sh cce-firstboot.service config.txt

sudo -n cp userconf.txt mount/boot/userconf.txt
echo >&2 "Updating config.txt:"
diff >&2 mount/boot/config.txt config.txt || true
sudo -n cp config.txt mount/boot/config.txt
sudo -n touch mount/boot/ssh

sudo -n mkdir -p mount/opt/
sudo -n cp firstboot.sh mount/opt/firstboot.sh
chmod +x firstboot-wifi.sh
sudo -n cp firstboot-wifi.sh mount/opt/firstboot-wifi.sh
sudo -n cp cce-firstboot.service mount/etc/systemd/system/cce-firstboot.service
sudo -n ln -s /etc/systemd/system/cce-firstboot.service mount/etc/systemd/system/multi-user.target.wants/cce-firstboot.service
sudo -n cp tskey /etc/tskey

# Remove mountpoint (-R ecursive -d etach loop device)
sudo -n umount -Rd mount/
sudo -n losetup -d "$LODEV"
sync

echo >&2 "Baseline image ready"
