#!/bin/bash

# Variables
CONTROLLER_HOST="192.168.12.114"

# Update Apache configuration
echo "Updating Apache configuration for Keystone to use port 5001..."
sudo sed -i 's/5000/5001/g' /etc/apache2/sites-available/wsgi-keystone.conf

# Enable the updated Keystone site configuration
echo "Enabling the updated Keystone site configuration..."
sudo a2ensite wsgi-keystone

# Restart Apache to apply changes
echo "Restarting Apache..."
sudo systemctl restart apache2

# Source the admin credentials
echo "Sourcing admin credentials..."
source admin-openrc.sh

# Update Keystone endpoints
echo "Updating Keystone endpoints to use port 5001..."
ENDPOINTS=$(openstack endpoint list -f value -c ID -c URL | grep 5000)
for ENDPOINT in $ENDPOINTS; do
    ID=$(echo $ENDPOINT | awk '{print $1}')
    URL=$(echo $ENDPOINT | awk '{print $2}' | sed 's/5000/5001/')
    openstack endpoint set --url $URL $ID
done

# Verify the updated Keystone endpoints
echo "Verifying the updated Keystone endpoints..."
openstack endpoint list
