#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to display error messages
error() {
    echo "Error: $1" >&2
    exit 1
}

# Determine the directory where the script is located
# This works even if the script is called via a symlink
get_script_dir() {
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do
        DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    echo "$DIR"
}

# Get the script directory
scriptDir="$(get_script_dir)"

# Define the backup destination
backupDest="$scriptDir/../assets/configs/xfce-configs.tar.gz"

# Ensure the backup directory exists
backupDir="$(dirname "$backupDest")"
mkdir -p "$backupDir" || error "Failed to create backup directory: $backupDir"

# Define the source directory (XFCE configs)
sourceDir="$HOME/.config/xfce4"

# Check if the source directory exists
if [ ! -d "$sourceDir" ]; then
    error "Source directory does not exist: $sourceDir"
fi

# Create the tar.gz archive
tar -czvf "$backupDest" -C "$HOME/.config" xfce4 || error "Failed to create tarball"

echo "Backup successfully created at $backupDest"
