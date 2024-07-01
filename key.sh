#!/bin/bash

# Set variables
DB_ROOT_PASS="root_db_pass"  # Change this to your MySQL root password
KEYSTONE_DBPASS="keystone_db_pass"  # Change this to your Keystone DB password
ADMIN_PASS="admin_pass"  # Change this to your admin password
CONTROLLER_HOST="192.168.12.144"  # Change this to your controller node hostname or IP

# Check Keystone service status
echo "Checking Keystone service status..."
sudo systemctl status snap.microstack.keystone.service

# Check Keystone logs
echo "Checking Keystone logs..."
sudo tail -f /var/log/keystone/keystone.log &

# Verify Keystone configuration
echo "Verifying Keystone configuration..."
sudo grep -A 5 '\[database\]' /etc/keystone/keystone.conf
sudo grep -A 5 '\[token\]' /etc/keystone/keystone.conf

# Sync Keystone database
echo "Syncing Keystone database..."
sudo keystone-manage db_sync

# Initialize Fernet keys
echo "Initializing Fernet keys..."
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap Keystone
echo "Bootstrapping Keystone..."
sudo keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-internal-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-public-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-region-id RegionOne

# Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

# Create and source OpenStack RC file
echo "Creating and sourcing OpenStack RC file..."
cat <<EOF > admin-openrc.sh
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$CONTROLLER_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

source admin-openrc.sh

# Verify Keystone
echo "Verifying Keystone..."
openstack token issue
