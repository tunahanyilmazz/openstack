#!/bin/bash

# Set variables
DB_ROOT_PASS="12345"  # Replace with your MySQL root password
KEYSTONE_DBPASS="1234567"  # Replace with your Keystone DB password
ADMIN_PASS="123"  # Replace with your admin password
CONTROLLER_HOST="192.168.12.114"  # Replace with your controller node hostname or IP

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update -y && sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y software-properties-common
sudo add-apt-repository cloud-archive:train -y
sudo apt update -y
sudo apt install -y keystone apache2 libapache2-mod-wsgi-py3 mariadb-server python3-pymysql

# Configure MySQL for Keystone
echo "Configuring MySQL for Keystone..."
sudo mysql -u root -p$DB_ROOT_PASS <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;
EXIT;
EOF

# Configure Keystone
echo "Configuring Keystone..."
sudo sed -i "s|#connection = sqlite:////var/lib/keystone/keystone.db|connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CONTROLLER_HOST/keystone|g" /etc/keystone/keystone.conf
sudo sed -i "s|#provider = uuid|provider = fernet|g" /etc/keystone/keystone.conf

# Populate the Keystone database
echo "Populating Keystone database..."
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

# Configure Apache
echo "Configuring Apache..."
sudo sed -i "s|#ServerName www.example.com:80|ServerName $CONTROLLER_HOST|g" /etc/apache2/apache2.conf
sudo ln -s /usr/share/keystone/wsgi-keystone.conf /etc/apache2/sites-available/keystone.conf
sudo a2ensite keystone
sudo service apache2 restart

# Set up OpenStack environment variables
echo "Setting up OpenStack environment variables..."
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

echo "Keystone installation and configuration completed successfully."
