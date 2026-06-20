#!/bin/sh
set -e
IMAGES_DIR="images"
mkdir -p "$IMAGES_DIR"

current_date=$(date +%Y%m%d)
counter=1
while [ -e "$IMAGES_DIR/fsuki.${current_date}$(printf %02d $counter).efi" ]; do
    counter=$((counter + 1))
done
image="fsuki.${current_date}$(printf %02d $counter).efi"

echo "Building image $image" >&2
echo >&2
docker run --privileged --rm -i \
    -v "$PWD":/mnt -w /root \
    "alpine:latest" /mnt/build-inner.sh "/mnt/$IMAGES_DIR/$image" >&2
echo "$image"
