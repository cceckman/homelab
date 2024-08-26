
# Get the WLAN interface config file by decrypting it.
redo-ifchange wpa_supplicant.conf.encrypted
ansible-vault decrypt <wpa_supplicant.conf.encrypted >"$3"

