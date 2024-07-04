# Check MySQL service status
sudo systemctl status mysql

# Start MySQL service if it's not running
sudo systemctl start mysql

# Check MySQL error logs
sudo cat /var/log/mysql/error.log

# Edit MySQL configuration file
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# Check disk space and permissions
df -h
sudo ls -ld /var/run/mysqld
sudo ls -l /var/run/mysqld
sudo chown -R mysql:mysql /var/run/mysqld

# Remove and recreate MySQL socket file directory
sudo rm -rf /var/run/mysqld
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld

# Restart MySQL service
sudo systemctl restart mysql

# Backup MySQL data (if necessary)
sudo tar -cvzf mysql_backup.tar.gz /var/lib/mysql

# Remove MySQL (if necessary)
sudo apt-get remove --purge mysql-server mysql-client mysql-common
sudo apt-get autoremove
sudo apt-get autoclean

# Reinstall MySQL (if necessary)
sudo apt-get update
sudo apt-get install mysql-server

# Secure MySQL installation
sudo mysql_secure_installation

# Start and enable MySQL service
sudo systemctl start mysql
sudo systemctl enable mysql

# Verify MySQL connection
mysql -u root -p
