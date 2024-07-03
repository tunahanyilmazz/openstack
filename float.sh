#!/bin/bash

# Allocate a Floating IP
echo "Allocating a Floating IP..."
FLOATING_IP=$(openstack floating ip create public -f value -c floating_ip_address)
echo "Floating IP allocated: $FLOATING_IP"

# Associate the Floating IP with the VM
echo "Associating the Floating IP with the VM..."
openstack server add floating ip <VM_NAME> $FLOATING_IP

echo "Floating IP $FLOATING_IP associated with VM <VM_NAME>"

# Output the command to access the VM
echo "To access the VM, use the following command:"
echo "ssh -i ~/.ssh/id_rsa cirros@$FLOATING_IP"
