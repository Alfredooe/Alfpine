#!/bin/sh
set -e
IMAGES_DIR="images"
image=$(ls -1 images/fsuki.*.efi 2>/dev/null | xargs -n1 basename | sort | tail -n 1)
device="$1"

if [ -z "$image" ]; then
    echo "No image found. Run 'make build' first."
    exit 1
fi
if [ -z "$device" ]; then
    echo "Usage: make flash DEVICE=/dev/sdb"
    exit 1
fi

echo "Flashing $image to $device"
echo "WARNING: This will DESTROY all data on $device!"
echo "Press Enter to continue or Ctrl-C to abort..."
read -r _

FLASH_IMG=$(mktemp)
cleanup() { rm -f "$FLASH_IMG"; }
trap cleanup EXIT

docker run --rm -v "$PWD/$IMAGES_DIR":/images -v "$(dirname "$FLASH_IMG")":/output \
    alpine:latest sh -c '
        apk add --no-cache dosfstools mtools &&
        truncate -s 256M /output/'"$(basename "$FLASH_IMG")"' &&
        printf "label: gpt\ntype=uefi" | sfdisk /output/'"$(basename "$FLASH_IMG")"' &&
        mformat -i /output/'"$(basename "$FLASH_IMG")"'@@$((1024*1024)) -F 32 -v FSUKI &&
        mmd -i /output/'"$(basename "$FLASH_IMG")"'@@$((1024*1024)) ::EFI &&
        mmd -i /output/'"$(basename "$FLASH_IMG")"'@@$((1024*1024)) ::EFI/BOOT &&
        mcopy -i /output/'"$(basename "$FLASH_IMG")"'@@$((1024*1024)) /images/'"$image"' ::EFI/BOOT/BOOTX64.EFI
    '

sudo dd of="$device" if="$FLASH_IMG" bs=1M status=progress conv=fsync
sudo eject "$device" 2>/dev/null || true
echo "Done! Boot from $device with UEFI."
