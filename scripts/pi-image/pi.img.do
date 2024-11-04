
set -eu
redo-ifchange rpi-64.img

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

# isolcpus for better LED matrix performance:
# https://access.redhat.com/solutions/480473
# For SPI use for NeoPixel driver:
# https://github.com/jgarff/rpi_ws281x?tab=readme-ov-file#spi
# 1: replace only on the first line
sudo sed -i "1 s/$/ isolcpus=3 spidev.bufsiz=32768/" mount/boot/cmdline.txt

sudo -n mkdir -p mount/opt/
sudo -n cp firstboot.sh mount/opt/firstboot.sh
sudo -n cp firstboot-wifi.sh mount/opt/firstboot-wifi.sh
sudo -n cp cce-firstboot.service mount/etc/systemd/system/cce-firstboot.service
sudo -n ln -s /etc/systemd/system/cce-firstboot.service mount/etc/systemd/system/multi-user.target.wants/cce-firstboot.service

# Remove mountpoint (-R ecursive -d etach loop device)
sudo -n umount -Rd mount/
sudo -n losetup -d "$LODEV"
sync

echo >&2 "Baseline image ready"
