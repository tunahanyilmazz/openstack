#!/bin/bash

# Set variables
NEW_ROOT_PASS="new_password"  # Change this to your new MySQL root password

# Stop MySQL Service
sudo systemctl stop mysql

# Start MySQL in Safe Mode
sudo mysqld_safe --skip-grant-tables &

# Give MySQL time to start in safe mode
sleep 5

# Connect to MySQL and reset the root password
sudo mysql -u root <<EOF
USE mysql;
UPDATE user SET authentication_string=PASSWORD('$NEW_ROOT_PASS') WHERE User='root';
FLUSH PRIVILEGES;
EXIT;
EOF

# Stop the Safe Mode MySQL Process
sudo pkill mysqld

# Give MySQL time to stop safe mode process
sleep 5

# Start the MySQL Service Normally
sudo systemctl start mysql

# Verify MySQL Root Access
echo "Trying to login with the new root password to verify..."
sudo mysql -u root -p$NEW_ROOT_PASS -e "SHOW DATABASES;"

if [ $? -eq 0 ]; then
  echo "Root password reset successfully and verified."
else
  echo "Failed to reset root password or verify the new password."
fi
