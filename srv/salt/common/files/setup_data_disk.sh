#!/bin/bash
set -e

# Script to find, format and mount a data disk for Solana
# This works for both AWS and GCP with different device naming schemes

# Default mount point
MOUNT_POINT="/mnt/solana"
OWNER="solana"
GROUP="solana"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mount-point)
            MOUNT_POINT="$2"
            shift 2
            ;;
        --owner)
            OWNER="$2"
            shift 2
            ;;
        --group)
            GROUP="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Find the root device
ROOT_DEVICE=$(mount | grep " / " | cut -d' ' -f1 | sed 's/[0-9]*$//')
echo "Root device: $ROOT_DEVICE"

# Find all block devices
DEVICES=$(lsblk -dpno NAME | grep -v loop)
echo "Available devices: $DEVICES"

# Function to check if a device is a partition
is_partition() {
    local dev=$1
    
    # For standard devices (sda, xvda), check if it ends with a number
    if [[ $dev =~ ^/dev/(sd|xvd|vd)[a-z]+[0-9]+$ ]]; then
        return 0  # True, it's a partition
    fi
    
    # For NVMe devices, check if it's a partition by looking for 'p' followed by a number at the end
    if [[ $dev =~ ^/dev/nvme[0-9]+n[0-9]+p[0-9]+$ ]]; then
        return 0  # True, it's a partition
    fi
    
    # Check if it's a root device
    if [[ "$dev" == "$ROOT_DEVICE"* ]]; then
        return 0  # True, treat as partition (skip it)
    fi
    
    # Not a partition
    return 1
}

# Find the largest non-root disk
LARGEST_DISK=""
LARGEST_SIZE=0

for DEV in $DEVICES; do
    # Check if this is a partition or root device
    if is_partition "$DEV"; then
        echo "Skipping partition or root device: $DEV"
        continue
    fi
    
    # Get size in bytes
    SIZE=$(lsblk -bno SIZE "$DEV" | head -n1)
    echo "Device $DEV has size: $SIZE bytes"
    
    if [[ $SIZE -gt $LARGEST_SIZE ]]; then
        LARGEST_SIZE=$SIZE
        LARGEST_DISK=$DEV
        echo "New largest disk: $LARGEST_DISK ($SIZE bytes)"
    fi
done

# If we found a disk, use it
if [[ -n "$LARGEST_DISK" ]]; then
    DEVICE="$LARGEST_DISK"
    HUMAN_SIZE=$(numfmt --to=iec-i --suffix=B $LARGEST_SIZE)
    echo "Found data disk: $DEVICE (Size: $HUMAN_SIZE)"
else
    # If no suitable disk was found, check if we're running in a cloud environment
    # and try alternative methods
    
    # Check for common device patterns
    echo "No disk found through size comparison. Checking for common device patterns..."
    
    # List all devices again for debugging
    echo "All available devices:"
    lsblk -p
    
    # Try to find a secondary NVMe device
    NVME_DEVICES=$(ls /dev/nvme*n* 2>/dev/null | grep -v "${ROOT_DEVICE}")
    if [[ -n "$NVME_DEVICES" ]]; then
        # Take the first NVMe device that's not the root
        for NVME_DEV in $NVME_DEVICES; do
            if ! is_partition "$NVME_DEV"; then
                DEVICE="$NVME_DEV"
                echo "Found NVMe device: $DEVICE"
                break
            fi
        done
    fi
    
    # If still no device, check for other common patterns
    if [[ -z "$DEVICE" && -e /dev/xvdb ]]; then
        DEVICE="/dev/xvdb"
        echo "Found AWS EBS device: $DEVICE"
    elif [[ -z "$DEVICE" && -e /dev/sdb ]]; then
        DEVICE="/dev/sdb"
        echo "Found standard SCSI device: $DEVICE"
    fi
    
    # If still no device found, exit
    if [[ -z "$DEVICE" ]]; then
        echo "No suitable data disk found. Exiting."
        exit 1
    fi
fi

# Check if the mount point already exists and is mounted
if [ -d "$MOUNT_POINT" ]; then
    # Check if it's already a mount point
    if mountpoint -q "$MOUNT_POINT"; then
        echo "$MOUNT_POINT is already mounted. Skipping mount."
        exit 0
    fi
    
    # Check if directory has content
    if [ "$(ls -A "$MOUNT_POINT" 2>/dev/null)" ]; then
        echo "WARNING: $MOUNT_POINT exists and contains data."
        echo "Moving existing data to ${MOUNT_POINT}.bak"
        mv "$MOUNT_POINT" "${MOUNT_POINT}.bak"
        mkdir -p "$MOUNT_POINT"
    fi
else
    mkdir -p "$MOUNT_POINT"
fi

# Format and mount the device
echo "Formatting $DEVICE with ext4..."
mkfs.ext4 -F "$DEVICE"

echo "Mounting $DEVICE to $MOUNT_POINT..."
mount "$DEVICE" "$MOUNT_POINT"

# Add to fstab for persistence across reboots
if ! grep -q "$DEVICE $MOUNT_POINT" /etc/fstab; then
    echo "Adding entry to /etc/fstab..."
    echo "$DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
fi

# Set ownership
if [[ -n "$OWNER" && -n "$GROUP" ]]; then
    echo "Setting ownership to $OWNER:$GROUP..."
    chown -R "$OWNER":"$GROUP" "$MOUNT_POINT"
fi

echo "Disk setup completed successfully."
exit 0 