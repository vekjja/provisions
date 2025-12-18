#!/bin/bash
# Script to completely remove SMB/Samba and free the drives

set -e

echo "=========================================="
echo "SMB/Samba Removal Script"
echo "=========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run with sudo"
    exit 1
fi

echo "Step 1: Stopping SMB services..."
systemctl stop smbd 2>/dev/null || echo "  smbd service not running or already stopped"
systemctl stop nmbd 2>/dev/null || echo "  nmbd service not running or already stopped"

echo ""
echo "Step 2: Disabling SMB services..."
systemctl disable smbd 2>/dev/null || echo "  smbd service not enabled"
systemctl disable nmbd 2>/dev/null || echo "  nmbd service not enabled"

echo ""
echo "Step 3: Removing SMB firewall rules..."
ufw delete allow 139/tcp comment 'SMB NetBIOS session' 2>/dev/null || echo "  Firewall rule 139/tcp not found"
ufw delete allow 445/tcp comment 'SMB over TCP' 2>/dev/null || echo "  Firewall rule 445/tcp not found"
ufw delete allow 137/udp comment 'SMB NetBIOS name' 2>/dev/null || echo "  Firewall rule 137/udp not found"
ufw delete allow 138/udp comment 'SMB NetBIOS datagram' 2>/dev/null || echo "  Firewall rule 138/udp not found"

echo ""
echo "Step 4: Removing SMB users from Samba database..."
if command -v pdbedit &> /dev/null; then
    # Get list of SMB users and remove them
    pdbedit -L 2>/dev/null | cut -d: -f1 | while read -r user; do
        if [ -n "$user" ]; then
            echo "  Removing SMB user: $user"
            pdbedit -x "$user" 2>/dev/null || echo "    Failed to remove user $user (may not exist)"
        fi
    done
else
    echo "  pdbedit not found, skipping user removal"
fi

echo ""
echo "Step 5: Unmounting SMB share directories..."
# Common SMB share mount points (adjust if needed)
SHARE_DIRS=(
    "/mnt/hdd/tera"
    "/mnt/hdd/barracuda"
    "/mnt/ssd/movies"
    "/mnt/ssd/series"
)

for dir in "${SHARE_DIRS[@]}"; do
    if mountpoint -q "$dir" 2>/dev/null; then
        echo "  Unmounting $dir..."
        umount "$dir" 2>/dev/null && echo "    Successfully unmounted $dir" || echo "    Failed to unmount $dir (may be in use)"
    else
        echo "  $dir is not mounted, skipping"
    fi
done

echo ""
echo "Step 6: Removing Samba configuration files..."
rm -f /etc/samba/smb.conf
rm -f /etc/samba/smb.conf.bak
rm -f /etc/samba/smb.conf.old
# Remove all backup files
find /etc/samba -name "smb.conf.backup.*" -delete 2>/dev/null || true
echo "  Samba configuration files and backups removed"

echo ""
echo "Step 7: Removing Samba packages..."
apt-get remove --purge -y samba samba-common-bin 2>/dev/null || echo "  Samba packages not installed or already removed"
apt-get autoremove -y
apt-get autoclean

echo ""
echo "Step 8: Cleaning up Samba directories..."
rm -rf /etc/samba
rm -rf /var/lib/samba/private/*
rm -rf /var/lib/samba/usershare/*
rm -rf /var/cache/samba/*
rm -rf /var/log/samba/*.log 2>/dev/null || true
echo "  Samba directories and configuration removed"

echo ""
echo "=========================================="
echo "SMB/Samba removal complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - SMB services stopped and disabled"
echo "  - Firewall rules removed"
echo "  - Samba packages uninstalled"
echo "  - Configuration files removed"
echo "  - SMB users removed from database"
echo "  - Share directories unmounted"
echo ""
echo "Note: Mount points still exist but are unmounted."
echo "      To remount drives, use your fstab configuration."

