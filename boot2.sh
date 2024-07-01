#!/bin/bash

# Set variables
CONTROLLER_NAME="sunbeam-controller"
LOCALE="en_US.UTF-8"
TF_CONFIG_PATH="$HOME/snap/openstack/current/.terraformrc"

# Function to handle dpkg errors
handle_dpkg_errors() {
    sudo dpkg --configure -a
    sudo apt-get install -f -y
}

# Function to destroy existing Juju controllers and services
destroy_juju() {
    echo "Destroying existing Juju controllers and services..."
    sudo juju destroy-controller -y --destroy-all-models --destroy-storage $CONTROLLER_NAME || true
    sudo rm -rf /var/lib/juju || true
}

# Function to configure Terraform
configure_terraform() {
    echo "Configuring Terraform..."
    sudo mkdir -p $(dirname $TF_CONFIG_PATH)
    echo 'provider_installation {
        filesystem_mirror {
            path    = "/snap/openstack/current/terraform-provider-registry"
            include = ["registry.terraform.io/*/*"]
        }
        direct {
            exclude = ["registry.terraform.io/*/*"]
        }
    }' | sudo tee $TF_CONFIG_PATH
}

# Function to fix locale settings
fix_locale() {
    fix_ssh_permissions
}

# Function to disable firewall temporarily
disable_firewall() {
    echo "Disabling firewall..."
    sudo ufw disable
}

# Function to bootstrap Sunbeam cluster
bootstrap_sunbeam() {
    echo "Bootstrapping Sunbeam cluster..."
    sudo sunbeam cluster bootstrap --accept-defaults
}

# Execute functions
handle_dpkg_errors
destroy_juju
configure_terraform
fix_locale
fix_ssh_permissions
disable_firewall

# Bootstrap Sunbeam
bootstrap_sunbeam

# Check the success of the bootstrap process
if [ $? -eq 0 ]; then
    echo "Sunbeam cluster bootstrapped successfully."
else
    echo "Failed to bootstrap Sunbeam cluster."
fi
