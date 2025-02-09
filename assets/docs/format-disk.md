
Ext4 (For Linux use)
NTFS (For Windows use)
FAT32 (For cross-platform use, but with a 4GB file size limit)
XFS (For large files and databases)

```sh
device=/dev/sde
lsblk
please umount ${device}$
lsblk
sudo wipefs --all ${device}$
cls
lsblk
sudo partprobe ${device}$
sudo parted ${device}$ mklabel gpt
sudo parted -a optimal ${device} mkpart primary ext4 0% 100%
sudo mkfs.ext4 ${device}
sudo e2label ${device}1 my_ssd  # For Ext4
# sudo xfs_admin -L my_ssd ${device}1  # For XFS
```