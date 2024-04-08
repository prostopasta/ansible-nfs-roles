#!/usr/bin/env bash

set -xe

# THIS SCRIPT WILL CREATE SSH KEYPAIR AND DISTRIBUTE ACROSS ALL NODES

ssh-keygen -b 2048 -t rsa -f /home/vagrant/.ssh/id_rsa -q -N ""

# LOOPING THROUGH AND DISTRIBUTING THE KEY

for val in controller host01 host02; do
	echo "-------------------- COPYING KEY TO ${val^^} NODE ------------------------------"
	sshpass -p 'vagrant' ssh-copy-id -o "StrictHostKeyChecking=no" vagrant@$val
done

# CREATE THE INVENTORY FILE

GITHUB_REPO="https://github.com/prostopasta/ansible-nfs-roles.git"
PROJECT_DIRECTORY="/home/vagrant/ansible-nfs-roles"

git clone $GITHUB_REPO
cd $PROJECT_DIRECTORY || false

# Creating the inventory file for all 3 nodes to run some adhoc command.

echo -e "controller\n\n[servers]\nhost01\n\n[clients]\nhost02" > inventory
echo -e "[defaults]\ninventory = inventory" > ansible.cfg
echo -e "-------------------- RUNNING ANSBILE ADHOC COMMAND - UPTIME ------------------------------"
echo

# running adhoc command to see if everything is fine

ansible all -i inventory -m "shell" -a "uptime"
echo