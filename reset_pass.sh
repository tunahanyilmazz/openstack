#!/bin/bash

# Set variables
NEW_ROOT_PASS="new_password"  # Change this to your new MySQL root password

# Stop MySQL Service
echo "Stopping MySQL service..."
sudo systemctl stop mysql

# Start MySQL in Safe Mode
echo "Starting MySQL in safe mode..."
sudo mysqld_safe --skip-grant-tables &

# Give MySQL time to start in safe mode
sleep 5

# Connect to MySQL and reset the root password
echo "Resetting MySQL root password..."
sudo mysql -u root <<EOF
USE mysql;
UPDATE user SET authentication_string=PASSWORD('$NEW_ROOT_PASS') WHERE User='root';
FLUSH PRIVILEGES;
EXIT;
EOF

# Stop the Safe Mode MySQL Process
echo "Stopping MySQL safe mode process..."
sudo pkill mysqld

# Give MySQL time to stop safe mode process
sleep 5

# Start the MySQL Service Normally
echo "Starting MySQL service normally..."
sudo systemctl start mysql

# Verify MySQL Root Access
echo "Verifying new root password..."
if sudo mysql -u root -p$NEW_ROOT_PASS -e "SHOW DATABASES;" > /dev/null 2>&1; then
  echo "Root password reset successfully and verified."
else
  echo "Failed to reset root password or verify the new password."
fi
