#!/bin/bash

# Update and Upgrade the System
sudo apt update -y && sudo apt upgrade -y
sudo reboot

# Wait for the system to reboot
echo "Waiting for the system to reboot..."
sleep 60

# Create Stack user and assign sudo privilege
sudo adduser --shell /bin/bash --home /opt/stack --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# Switch to the stack user
sudo su - stack << 'EOF'

# Install git
sudo apt install git -y

# Download DevStack
git clone https://opendev.org/openstack/devstack

# Navigate to the devstack directory
cd devstack

# Create local.conf configuration file
cat <<EOL > local.conf
[[local|localrc]]
# Password for KeyStone, Database, RabbitMQ and Service
ADMIN_PASSWORD=StrongAdminSecret
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
# Host IP - get your Server/VM IP address from ip addr command
HOST_IP=$(hostname -I | awk '{print $1}')
EOL

# Install OpenStack with DevStack
./stack.sh

EOF

echo "OpenStack installation completed. Access it via a web browser at http://$(hostname -I | awk '{print $1}')/dashboard"
