#!/bin/bash
# Script to uninstall and clean up NFS server

set -e

echo "Stopping NFS services..."
sudo systemctl stop nfs-server
sudo systemctl stop rpcbind

echo "Disabling NFS services..."
sudo systemctl disable nfs-server
sudo systemctl disable rpcbind

echo "Unexporting all NFS shares..."
sudo exportfs -ua

echo "Backing up /etc/exports to /etc/exports.backup..."
sudo cp /etc/exports /etc/exports.backup 2>/dev/null || echo "No existing /etc/exports file found"

echo "Clearing /etc/exports..."
sudo truncate -s 0 /etc/exports

echo "Removing NFS firewall rules..."
sudo ufw delete allow 111/tcp comment 'NFS rpcbind' 2>/dev/null || echo "Firewall rule 111/tcp not found or already removed"
sudo ufw delete allow 111/udp comment 'NFS rpcbind' 2>/dev/null || echo "Firewall rule 111/udp not found or already removed"
sudo ufw delete allow 2049/tcp comment 'NFS server' 2>/dev/null || echo "Firewall rule 2049/tcp not found or already removed"
sudo ufw delete allow 2049/udp comment 'NFS server' 2>/dev/null || echo "Firewall rule 2049/udp not found or already removed"
sudo ufw delete allow 32765:65535/tcp comment 'NFS dynamic ports' 2>/dev/null || echo "Firewall rule 32765:65535/tcp not found or already removed"
sudo ufw delete allow 32765:65535/udp comment 'NFS dynamic ports' 2>/dev/null || echo "Firewall rule 32765:65535/udp not found or already removed"

echo "Uninstalling NFS packages..."
sudo apt-get remove --purge -y nfs-kernel-server rpcbind
sudo apt-get autoremove -y

echo "NFS has been uninstalled and cleaned up."
echo "Note: /etc/exports has been backed up to /etc/exports.backup if it existed."

