#!/bin/bash

# Function to display a warning and ask for confirmation
confirm() {
    read -r -p "${1} [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# Warning message
echo "WARNING: This script will wipe user data, remove installed applications, and reset system configurations."
echo "Make sure you have backed up important data."

# Confirm execution
if ! confirm "Do you want to proceed?"; then
    echo "Operation cancelled."
    exit 1
fi

# Delete user data
echo "Deleting user data..."
sudo rm -rf /home/*
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/log/*

# Remove installed applications and configurations
echo "Removing installed applications and configurations..."
sudo apt-get remove --purge $(dpkg --get-selections | grep -v deinstall | grep -v "install ok installed ubuntu-" | awk '{print $1}') -y
sudo apt-get autoremove -y
sudo apt-get clean

# Reset configuration files
echo "Resetting configuration files..."
sudo rm -rf /etc/*
sudo mkdir /etc

# Reinstall core system packages
echo "Reinstalling core system packages..."
sudo apt-get install --reinstall ubuntu-standard ubuntu-server -y
sudo apt-get -f install
sudo dpkg --configure -a

# Reset APT sources list to default
echo "Resetting APT sources list to default..."
sudo bash -c 'cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://security.ubuntu.com/ubuntu jammy-security universe
deb http://security.ubuntu.com/ubuntu jammy-security multiverse
EOF'

# Update package list
sudo apt-get update

# Final message and reboot
echo "System reset is complete. The server will reboot now."
sudo reboot
