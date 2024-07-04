#!/bin/bash

# Define variables
DB_HOST=localhost
DB_USER=keystone
DB_PASS=12345
ADMIN_PASS=12345
KEYSTONE_IP=192.168.12.111

# Update and install keystone
sudo apt update
sudo apt install -y keystone apache2 libapache2-mod-wsgi-py3

# Configure keystone.conf
sudo cat <<EOL > /etc/keystone/keystone.conf
[database]
connection = mysql+pymysql://$DB_USER:$DB_PASS@$DB_HOST/keystone

[token]
provider = fernet

[DEFAULT]
admin_token = $ADMIN_PASS
EOL

# Initialize the keystone database
sudo keystone-manage db_sync

# Initialize Fernet keys
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap the keystone service
sudo keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$KEYSTONE_IP:5000/v3/ \
  --bootstrap-internal-url http://$KEYSTONE_IP:5000/v3/ \
  --bootstrap-public-url http://$KEYSTONE_IP:5000/v3/ \
  --bootstrap-region-id RegionOne

# Create an Apache configuration for Keystone
sudo cat <<EOL > /etc/apache2/sites-available/keystone.conf
<VirtualHost *:5000>
    ServerName keystone

    WSGIDaemonProcess keystone processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIRestrictEmbedded On
    WSGILoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

    <Directory /usr/bin>
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/keystone.log
    LogLevel info
    CustomLog /var/log/apache2/keystone_access.log combined
</VirtualHost>
EOL

# Enable the Keystone site and the WSGI module
sudo a2enmod wsgi
sudo a2ensite keystone
sudo service apache2 restart

# Create systemd service unit file for Keystone
sudo cat <<EOL > /etc/systemd/system/keystone.service
[Unit]
Description=OpenStack Keystone Service
After=network.target

[Service]
Type=simple
User=keystone
ExecStart=/usr/bin/keystone-wsgi-public
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable Keystone service
sudo systemctl daemon-reload
sudo systemctl enable keystone
sudo systemctl start keystone

# Create admin-openrc file
cat <<EOL > ~/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$KEYSTONE_IP:5000/v3
export OS_IDENTITY_API_VERSION=3
EOL

echo "Keystone setup complete. Please source the admin-openrc file to use OpenStack CLI."
echo "To do this, run: source ~/admin-openrc"
