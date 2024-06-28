#!/bin/bash

# Set variables
DB_ROOT_PASS="root_db_pass"  # Change this to your MySQL root password
KEYSTONE_DBPASS="keystone_db_pass"  # Change this to your Keystone DB password
ADMIN_PASS="admin_pass"  # Change this to your admin password
CONTROLLER_HOST="192.168.12.144"  # Change this to your controller node hostname or IP

# Function to handle dpkg errors
handle_dpkg_errors() {
    sudo dpkg --configure -a
    sudo apt-get install -f -y
}

# Install MySQL Server
sudo apt update
sudo apt install mysql-server -y || handle_dpkg_errors

# Secure MySQL Installation
sudo mysql_secure_installation <<EOF

y
$DB_ROOT_PASS
$DB_ROOT_PASS
y
y
y
y
EOF

# Create Keystone Database
sudo mysql -u root -p$DB_ROOT_PASS <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;
EXIT;
EOF

# Install Keystone
sudo apt install keystone -y || handle_dpkg_errors

# Configure Keystone
sudo sed -i "s|#connection = sqlite:////var/lib/keystone/keystone.db|connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CONTROLLER_HOST/keystone|g" /etc/keystone/keystone.conf
sudo sed -i "s|#provider = uuid|provider = fernet|g" /etc/keystone/keystone.conf

# Populate Keystone Database
sudo keystone-manage db_sync

# Initialize Fernet Keys
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap the Identity Service
sudo keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-internal-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-public-url http://$CONTROLLER_HOST:5000/v3/ \
  --bootstrap-region-id RegionOne

# Restart Apache
sudo service apache2 restart

# Create OpenStack RC File
cat <<EOF > admin-openrc.sh
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$CONTROLLER_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

# Source the RC File
source admin-openrc.sh

# Verify Keystone
openstack token issue
