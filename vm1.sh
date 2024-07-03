#!/bin/bash

# Source the admin credentials
source admin-openrc.sh

# Variables
FLAVOR_NAME="small"
FLAVOR_VCPUS=1
FLAVOR_RAM=1024
FLAVOR_DISK=10
IMAGE_NAME="cirros"
IMAGE_URL="http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img"
IMAGE_FILE="cirros-0.5.2-x86_64-disk.img"
NETWORK_NAME="demo-net"
SUBNET_NAME="demo-subnet"
SUBNET_RANGE="192.168.1.0/24"
ROUTER_NAME="demo-router"
KEY_NAME="demo-key"
KEY_PATH="$HOME/.ssh/id_rsa.pub"
SECURITY_GROUP="default"
INSTANCE_NAME="demo-instance"

# Create flavor
echo "Creating flavor..."
openstack flavor create --id auto --vcpus $FLAVOR_VCPUS --ram $FLAVOR_RAM --disk $FLAVOR_DISK $FLAVOR_NAME

# Download and upload image
echo "Downloading and uploading image..."
wget $IMAGE_URL -O $IMAGE_FILE
openstack image create "$IMAGE_NAME" --file $IMAGE_FILE --disk-format qcow2 --container-format bare --public

# Create network and subnet
echo "Creating network and subnet..."
openstack network create $NETWORK_NAME
openstack subnet create --network $NETWORK_NAME --subnet-range $SUBNET_RANGE $SUBNET_NAME

# Create router and set gateway
echo "Creating router and setting gateway..."
openstack router create $ROUTER_NAME
openstack router add subnet $ROUTER_NAME $SUBNET_NAME
openstack router set $ROUTER_NAME --external-gateway public

# Create key pair
echo "Creating key pair..."
openstack keypair create --public-key $KEY_PATH $KEY_NAME

# Create security group rules
echo "Creating security group rules..."
openstack security group rule create --proto tcp --dst-port 22 $SECURITY_GROUP
openstack security group rule create --proto icmp $SECURITY_GROUP

# Launch VM
echo "Launching VM..."
NET_ID=$(openstack network list | grep $NETWORK_NAME | awk '{print $2}')
openstack server create --flavor $FLAVOR_NAME --image $IMAGE_NAME --nic net-id=$NET_ID --security-group $SECURITY_GROUP --key-name $KEY_NAME $INSTANCE_NAME

# Allocate and associate a floating IP (Optional)
echo "Allocating and associating floating IP..."
FLOATING_IP=$(openstack floating ip create public -f value -c floating_ip_address)
openstack server add floating ip $INSTANCE_NAME $FLOATING_IP

echo "VM launched successfully. You can access it using the following command:"
echo "ssh -i $HOME/.ssh/id_rsa cirros@$FLOATING_IP"
