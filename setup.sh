#!/bin/sh

# Enable openssh server
rc-update add sshd default

# Log rc system to find errors
# Logs will be in /var/log/rc.log
sed -i 's/#rc_logger="NO"/rc_logger="YES"/' /etc/rc.conf

# Configure networking
cat > /etc/network/interfaces <<-EOF
iface lo inet loopback
iface eth0 inet dhcp
EOF

ln -s networking /etc/init.d/net.lo
ln -s networking /etc/init.d/net.eth0

rc-update add net.eth0 default
rc-update add net.lo boot

# Create root ssh directory
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Grab config from DigitalOcean metadata service
cat > /bin/do-init <<-EOF
#!/bin/sh
resize2fs /dev/vda
wget -T 5 http://169.254.169.254/metadata/v1/hostname    -q -O /etc/hostname
wget -T 5 http://169.254.169.254/metadata/v1/public-keys -q -O /root/.ssh/authorized_keys
hostname -F /etc/hostname
chmod 600 /root/.ssh/authorized_keys
rc-update del do-init default
exit 0
EOF

# Create do-init OpenRC service
cat > /etc/init.d/do-init <<-EOF
#!/sbin/openrc-run
depend() {
    need net.eth0
}
command="/bin/do-init"
command_args=""
pidfile="/tmp/do-init.pid"
EOF

# Make do-init and service executable
chmod +x /etc/init.d/do-init
chmod +x /bin/do-init

# Enable do-init service
rc-update add do-init default


######################################################################
#
# Do initial setup (what would be "user-data" on digital ocean).
#
# (This and the "do-init" bit above replicate what "cloud-init" would do
# if it were possible to use it with alpine, which it isn't.  See the
# Ben Pye article referenced in the README for more info/explanation.)
#
# /bin/initial-setup is based on this user-data/cloud-init script from
# digital ocean, adopted for alpine linux.
#
# https://docs.digitalocean.com/products/droplets/getting-started/recommended-droplet-setup/

cat > /bin/initial-setup <<-EOF
#!/bin/sh

apk add --no-progress \
	bash \
	ufw

# set up the firewall
# cf. https://wiki.alpinelinux.org/wiki/Uncomplicated_Firewall
ufw default deny incoming
ufw default deny outgoing
ufw limit SSH         # open SSH port and protect against brute-force login attacks
ufw allow out 123/udp # allow outgoing NTP (Network Time Protocol)

# The following instructions will allow apk to work:
ufw allow out DNS     # allow outgoing DNS
ufw allow out 80/tcp  # allow outgoing HTTP traffic

yes | ufw enable     # enable the firewall
rc-update add ufw    # add UFW init scripts
# do "ufw status" to check on it

USERNAME="alp"
HOMEDIR="/home/\${USERNAME}"

# create user, then add user to two groups
adduser -h "\${HOMEDIR}" -s /bin/ash -D "\${USERNAME}"
adduser "\${USERNAME}" "\${USERNAME}"
adduser "\${USERNAME}" wheel

mkdir -p "\${HOMEDIR}/.ssh"
cp /root/.ssh/authorized_keys "\${HOMEDIR}/.ssh"
chmod 0700 "\${HOMEDIR}/.ssh"
chmod 0600 "\${HOMEDIR}/.ssh/authorized_keys"
chown -R "\${USERNAME}":"\${USERNAME}" "\${HOMEDIR}/.ssh"
# password login for root is already disallowed

rc-update del initial-setup default
exit 0
EOF

# Create initial-setup OpenRC service
cat > /etc/init.d/initial-setup <<-EOF
#!/sbin/openrc-run
depend() {
    need net.eth0
    need localmount
    need bootmisc
}
command="/bin/initial-setup
command_args=""
pidfile="/tmp/initial-setup.pid
EOF

# Make initial-setup and service executable
chmod +x /etc/init.d/initial-setup
chmod +x /bin/initial-setup

# Enable initial-setup service
rc-update add initial-setup default
