#!/bin/sh
set -e
IMAGES_DIR="images"
image="${1:-$(ls -1 images/fsuki.*.efi 2>/dev/null | xargs -n1 basename | sort | tail -n 1)}"
num_disks="${2:-1}"

if [ -z "$image" ]; then
    echo "No image found. Run 'make build' first."
    exit 1
fi

echo "Booting $image in QEMU ($num_disks data disk(s))..."
echo
docker run --rm -it --privileged \
    -p 2222:2222 -p 9000:9000 -p 9001:9001 -p 9100:9100 \
    -v "$PWD/$IMAGES_DIR":/images \
    alpine:latest sh -c '
        set -e
        apk add --no-cache qemu-system-x86_64 ovmf mtools xfsprogs
        truncate -s 600M /tmp/disk.img
        mkfs.vfat -F 32 /tmp/disk.img
        mmd -i /tmp/disk.img ::EFI
        mmd -i /tmp/disk.img ::EFI/BOOT
        mcopy -i /tmp/disk.img /images/'"$image"' ::EFI/BOOT/BOOTX64.EFI
        DRIVES=""
        for N in $(seq 0 $(( '"$num_disks"' - 1 ))); do
            truncate -s 2G /tmp/data${N}.img
            mkfs.xfs -q -i size=512 -n ftype=1 -L FSUKI_DATA${N} /tmp/data${N}.img
            DRIVES="$DRIVES -drive file=/tmp/data${N}.img,format=raw,if=virtio"
        done
        cp /usr/share/OVMF/OVMF_VARS.fd /tmp/OVMF_VARS.fd
        eval qemu-system-x86_64 \
            -M pc -m 2G -nographic \
            -accel kvm -accel tcg \
            -net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::9000-:9000,hostfwd=tcp::9001-:9001,hostfwd=tcp::9100-:9100 \
            -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd,readonly=on \
            -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
            -drive file=/tmp/disk.img,format=raw,if=virtio \
            $DRIVES
    '
