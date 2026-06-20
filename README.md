# fsuki

Alpine Linux as a single-file UKI — no disk, no bootloader, no root partition.
Everything in RAM. Reboot = factory reset.

Bundles **RustFS**, an S3-compatible object storage server, as a turnkey appliance.

## What you get

- **Console:** live TUI dashboard (RustFS status + logs, read-only)
- **SSH:** key-only auth on port 2222
- **S3 API:** `http://<host>:9000`
- **RustFS Console:** `http://<host>:9001` (login: `rustfsadmin` / `rustfsadmin`)
- **Prometheus metrics:** `http://<host>:9100/metrics` (node_exporter)

## Usage

```sh
make                  # build + run in QEMU (1 data disk)
make run DISKS=4      # build + run with 4 data disks
make build            # build the UKI only
make qemu             # run latest image in QEMU
make qemu DISKS=2     # run with 2 data disks
make flash DEVICE=/dev/sdb       # write to USB stick
make setup-data DEVICE=/dev/sdc  # format a data disk for RustFS
make clean-images                # delete all built images
```

Requires Docker for the build container and QEMU runner. No Docker inside the image.

## Hardware deployment

```sh
make flash DEVICE=/dev/sdb                              # bootable USB
sudo mkfs.xfs -i size=512 -n ftype=1 -L FSUKI_DATA0 /dev/sdc  # data disk
```

Plug both into target machine, boot from USB in UEFI mode. The data disk is
auto-discovered, formatted if needed, and mounted at `/data/disk0`. Add more
disks by labeling them `FSUKI_DATA1`, `FSUKI_DATA2`, etc.:

```sh
sudo mkfs.xfs -i size=512 -n ftype=1 -L FSUKI_DATA0 /dev/sdc
sudo mkfs.xfs -i size=512 -n ftype=1 -L FSUKI_DATA1 /dev/sdd
sudo mkfs.xfs -i size=512 -n ftype=1 -L FSUKI_DATA2 /dev/sde
```

On boot, fsuki auto-discovers all labeled disks and passes them to RustFS as
volumes.

## Ports

| Port | Service |
|------|---------|
| 2222 | SSH (key-only) |
| 9000 | RustFS S3 API |
| 9001 | RustFS Web Console |
| 9100 | Prometheus Node Exporter |

## Observability

RustFS exports traces, metrics, and logs via **OTLP/HTTP** (push-based). Point an
OpenTelemetry collector at RustFS:

```sh
export RUSTFS_OBS_ENDPOINT=http://otel-collector:4318
```

The node_exporter on port 9100 covers system-level metrics and works with any
Prometheus-compatible scraper.

## Customize

- **SSH key:** `root/root/.ssh/authorized_keys` — baked into the image
- **Packages:** edit `packages`
- **Root files:** drop into `root/` (copied verbatim into the image)
- **Services:** init scripts in `root/etc/init.d/`, enable in `setup.sh`
- **RustFS creds:** defaults `rustfsadmin` / `rustfsadmin`, override via env vars

## Architecture

```
UKI (.efi)
├── kernel (linux-lts)
├── initramfs
│   ├── Alpine base + packages (~150 MB)
│   └── RustFS binary (~285 MB, static musl)
└── cmdline: rdinit=/sbin/init
```

Everything loads into RAM at boot. Data disks are auto-discovered via XFS labels
and mounted at `/data/disk0`, `/data/disk1`, etc. Console shows the TUI dashboard;
SSH is the only way in.
