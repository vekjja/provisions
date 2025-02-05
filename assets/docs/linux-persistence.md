# How to Provision Linux Live USB Persistence
## Overview
This document will guide you through the process of creating a persistence volume for an Linux Live USB drive. This will allow you to save files and settings between reboots.

Determine the device name of the USB or disk drive you want to use:
```bash
sudo fdisk -l
```
The Following Bash Snippet will create a persistence volume on the USB drive. Replace `/dev/sdb2` with the device name of your USB drive. 

```bash
create a partition on the drive:
    •`n`, 
    • `p` for primary,
    • `1` for the first partition on the drive, and pressing Enter twice to accept the default values. Then type 
    • `w` to write the changes to the drive.
• Format the new partition as ext4:  
• Mount the new partition:

```bash
# =================== CONFIGURATION ======================
# IMPORTANT: Replace '/dev/nvme0n1' with your USB drive device.
export DEVICE="/dev/nvme0n1"

# Determine the correct partition name.
if [[ "$DEVICE" == *"nvme"* ]]; then 
    export PARTITION="${DEVICE}p1"
else 
    export PARTITION="${DEVICE}1"
fi

# Set the mount point for the persistence partition.
export MOUNT_POINT="/mnt/persistence"

# =================== PARTITIONING ======================
echo "Creating a new primary partition on ${DEVICE}..."
sudo fdisk "${DEVICE}" <<EOF
n
p
1


w
EOF

# =================== FORMATTING ======================
echo "Formatting ${PARTITION} as ext4 with label 'persistence'..."
sudo mkfs.ext4 -L persistence "${PARTITION}"

# =================== MOUNTING AND CONFIGURATION ======================
echo "Mounting ${PARTITION} to ${MOUNT_POINT}..."
sudo mkdir -p "${MOUNT_POINT}"
sudo mount "${PARTITION}" "${MOUNT_POINT}"

echo "Creating persistence configuration file..."
echo "/ union" | sudo tee "${MOUNT_POINT}/persistence.conf" > /dev/null

# =================== FINALIZATION ======================
echo "Persistence partition configured successfully."
echo "Unmounting ${PARTITION}..."
sudo umount "${MOUNT_POINT}"
echo "Done. Reboot your system with the 'persistence' boot parameter to enable persistence."
```
