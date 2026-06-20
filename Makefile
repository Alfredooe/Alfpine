.PHONY: build run qemu flash setup-data clean-images

DISKS ?= 1
DEVICE ?=

build:
	@scripts/build.sh >&2

qemu:
	@scripts/qemu.sh "" $(DISKS)

run:
	@scripts/build.sh >&2 && scripts/qemu.sh "" $(DISKS)

flash:
	@scripts/flash.sh $(DEVICE)

setup-data:
	@scripts/setup-data.sh $(DEVICE)

clean-images:
	rm -f images/fsuki.*.efi
