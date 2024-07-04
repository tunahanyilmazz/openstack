#!/bin/bash

# Define variables
DB_USER="root"
DB_PASS="12345"

# Step 1: Create a basic MySQL configuration file
cat <<EOL | sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

# Custom config should go here
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
EOL

# Step 2: Ensure MySQL has the correct permissions
sudo chown -R mysql:mysql /var/lib/mysql
sudo chown -R mysql:mysql /var/run/mysqld

# Step 3: Restart MySQL service
sudo systemctl restart mysql

# Step 4: Check MySQL service status
sudo systemctl status mysql

# Step 5: Ensure MySQL service is enabled to start on boot
sudo systemctl enable mysql

# Step 6: Check available memory and disk space
echo "Checking available memory and disk space..."
free -m
df -h

# Step 7: Secure MySQL installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation <<EOF

y
$DB_PASS
$DB_PASS
y
y
y
y
EOF

# Step 8: Verify MySQL connection
echo "Verifying MySQL connection..."
mysql -u $DB_USER -p$DB_PASS -e "SHOW DATABASES;"

# If the above command fails, prompt for manual password entry
if [ $? -ne 0 ]; then
  echo "Automatic connection failed. Please enter the MySQL root password manually."
  mysql -u $DB_USER -p -e "SHOW DATABASES;"
fi

echo "MySQL setup and verification complete."
