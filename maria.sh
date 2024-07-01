#!/bin/bash

# Set variables
DB_ROOT_PASS="12345"  # Replace with your MySQL root password
KEYSTONE_DBPASS="1234567"  # Replace with your desired Keystone DB password

# Create Keystone database and grant privileges
echo "Creating Keystone database and granting privileges..."

sudo mysql -u root -p$DB_ROOT_PASS <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;
EXIT;
EOF

echo "Keystone database created and privileges granted successfully."
