# Make a free-tier GCE VM:
# - e2-micro
# - Standard persistent disk (not "balanced", the default)
# - IP forwarding enabled
# - Premium network tier - alas, this is where we have to get IPv6 from
# - PTR records

gcloud compute instances create pvm1 \
    --zone=us-central1-c \
    --machine-type=e2-micro \
    --network-interface=address=34.56.231.75,external-ipv6-address=2600:1900:4000:4b32:0:3::,external-ipv6-prefix-length=96,ipv6-network-tier=PREMIUM,network-tier=PREMIUM,stack-type=IPV4_IPV6,subnet=default \
    --public-ptr \
    --public-ptr-domain=pvm1.cceckman.com. \
    --can-ip-forward \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --no-service-account \
    --no-scopes \
    --tags=ssh-server,http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=public-vm,image=projects/debian-cloud/global/images/debian-12-bookworm-v20241009,mode=rw,size=15,type=pd-standard \
    --shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# I'll need to update some firewall rules for DNS as well.

# DigitalOcean:
# Create reserved IPs in control panel
# Create droplet; "advanced options" to turn on IPv6 from the get-go
curl -X POST -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$TOKEN'' \
    -d '{"name":"pvm2.cceckman.com",
        "size":"s-1vcpu-512mb-10gb",
        "region":"nyc1",
        "image":"ubuntu-24-10-x64",
        "ipv6":true,
        "monitoring":true,
        "vpc_uuid":"d7a61fd2-465e-4a6b-8c19-a5aacd79d11a"}' \
    "https://api.digitalocean.com/v2/droplets"
# Manually add reserved IP
