#!/bin/sh
set -e
device="$1"
if [ -z "$device" ]; then
    echo "Usage: make setup-data DEVICE=/dev/sdc"
    exit 1
fi
echo "Setting up data disk: $device"
echo "WARNING: This will DESTROY all data on $device!"
echo "Press Enter to continue or Ctrl-C to abort..."
read -r _
sudo mkfs.xfs -i size=512 -n ftype=1 -L FSUKI_DATA0 "$device"
echo "Done. On next fsuki boot, $device will auto-mount at /data."
