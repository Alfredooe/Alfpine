# alfpine

Alpine Linux as a single-file UKI — no disk, no bootloader, no root partition.
Everything in RAM. Reboot = factory reset.

Bundles **RustFS**, an S3-compatible object storage server, as a turnkey appliance.

## What you get

- **Console:** live RustFS server logs (read-only, no shell)
- **SSH:** key-only auth on port 2222
- **S3 API:** `http://<host>:9000`
- **RustFS Console:** `http://<host>:9001` (login: `rustfsadmin` / `rustfsadmin`)
- **Prometheus metrics:** `http://<host>:9100/metrics` (node_exporter)

## Usage

```sh
./alfpine build          # Build the UKI
./alfpine run            # Build + test in QEMU
./alfpine qemu           # Run latest image in QEMU
./alfpine flash /dev/sdb # Write to USB stick
```

Requires Docker for the build container and QEMU runner. No Docker inside the image.

## Ports

| Port | Service |
|------|---------|
| 2222 | SSH (key-only) |
| 9000 | RustFS S3 API |
| 9001 | RustFS Web Console |
| 9100 | Prometheus Node Exporter |

## Observability

RustFS exports traces, metrics, and logs via **OTLP/HTTP** (push-based). Point an
OpenTelemetry collector at RustFS by setting `RUSTFS_OBS_ENDPOINT`:

```sh
export RUSTFS_OBS_ENDPOINT=http://otel-collector:4318
```

The node_exporter on port 9100 covers system-level metrics (CPU, memory, disk,
network) and works with any Prometheus-compatible scraper.

## Customize

- **SSH key:** `root/root/.ssh/authorized_keys` — baked into the image
- **Packages:** edit `packages`
- **Root files:** drop into `root/` (copied verbatim into the image)
- **Services:** init scripts in `root/etc/init.d/`, enable in `setup.sh`
- **RustFS creds:** defaults `rustfsadmin` / `rustfsadmin`, override via `RUSTFS_ROOT_USER` / `RUSTFS_ROOT_PASSWORD` env in `root/etc/init.d/rustfs`

## Architecture

```
UKI (.efi)
├── kernel (linux-lts)
├── initramfs
│   ├── Alpine base + packages (~150 MB)
│   └── RustFS binary (~285 MB, static musl)
└── cmdline: rdinit=/sbin/init
```

Everything loads into RAM at boot. No persistent state — mount a data disk at `/data`
for RustFS storage. Console tails RustFS logs; SSH is the only way in.
