#!/bin/bash

# Sync the Keystone database
echo "Syncing the Keystone database..."
sudo keystone-manage db_sync

# Initialize Fernet keys
echo "Initializing Fernet keys..."
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap Keystone
echo "Bootstrapping Keystone..."
sudo keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://CONTROLLER_HOST:5000/v3/ \
  --bootstrap-internal-url http://CONTROLLER_HOST:5000/v3/ \
  --bootstrap-public-url http://CONTROLLER_HOST:5000/v3/ \
  --bootstrap-region-id RegionOne

# Configure Apache to serve Keystone
echo "Configuring Apache to serve Keystone..."
sudo a2ensite wsgi-keystone
sudo systemctl restart apache2

# Create and source the admin OpenRC file
echo "Creating and sourcing the admin OpenRC file..."
cat <<EOF > admin-openrc.sh
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://CONTROLLER_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

source admin-openrc.sh

# Verify Keystone setup
echo "Verifying Keystone setup..."
openstack token issue
