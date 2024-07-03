#!/bin/bash

# Source the admin credentials
source ~/admin-openrc.sh

# List all VMs
echo "Listing all VMs..."
openstack server list

# Get VM name or ID from the user
echo "Enter the name or ID of the VM to view details:"
read VM_NAME_OR_ID

# Show the details of the specified VM
echo "Showing details of the VM: $VM_NAME_OR_ID"
openstack server show $VM_NAME_OR_ID
