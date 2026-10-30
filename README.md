# pi-sd-backup

Nightly live backup of a Raspberry Pi's SD card to a second SD card, using
`dd` — no unmount required. The Pi keeps running (it serves the home network)
while the copy proceeds.

## How it works

`backup.sh` clones the source device (`/dev/mmcblk0`) block-for-block onto a
destination device (`/dev/sdb`). A `sync` flushes buffers first to minimize
filesystem inconsistency; the copy uses `conv=noerror,sync` so read errors
don't abort the run and partition offsets stay aligned.

Because the source stays mounted, the backup is a *crash-consistent* snapshot,
not a clean one. The backup card may need an `fsck` on first boot — the Pi's
kernel runs this automatically.

## Requirements

- Root (raw block-device access).
- A destination card at least as large as the source.
- `dd`, `lsblk`, `blkid`, `sync`, `grep` (all standard on Raspberry Pi OS).

## Usage

```bash
# Dry run — prints the dd command, writes no data
sudo bash backup.sh --dry-run

# Real backup
sudo bash backup.sh
```

## Configuration

Override defaults via environment variables:

| Variable      | Default                     | Purpose                                              |
| ------------- | --------------------------- | ---------------------------------------------------- |
| `SOURCE_UUID` | *(unset)*                   | Pin source card by filesystem UUID                   |
| `DEST_UUID`   | *(unset)*                   | Pin destination card by filesystem UUID              |
| `SOURCE_DEV`  | `/dev/mmcblk0`              | Device to copy from (path or by-id; used if no UUID) |
| `DEST_DEV`    | `/dev/sdb`                  | Device to copy to (path or by-id; used if no UUID)   |
| `ENV_FILE`    | `.env` beside the script    | Path to the config file to source                    |
| `LOG_FILE`    | `/var/log/pi-sd-backup.log` | Log destination                                      |
| `LOG_LEVEL`   | `ERROR`                     | `ERROR` (quiet) or `INFO` (verbose)                  |

```bash
sudo LOG_LEVEL=INFO DEST_DEV=/dev/sdc bash backup.sh
```

### Pin devices by UUID (recommended)

Kernel names like `/dev/sdb` are **not stable** — plug order or a reboot can
reassign them, and `dd` will happily overwrite whatever `/dev/sdb` now points
at. Pin each card by its filesystem UUID instead; the script resolves the UUID
to the correct whole-disk device at runtime, so the copy always targets the
intended card.

Find a card's UUID (pick any partition on it):

```bash
sudo blkid
```

Keep real UUIDs **out of the repo** — put them in an env file on the Pi. Copy
the template and fill it in:

```bash
cp .env.example .env      # .env is gitignored
sudo blkid                # copy the UUIDs into .env
```

`.env` (never committed):

```sh
SOURCE_UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
DEST_UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

The script sources `.env` automatically (default: `.env` next to `backup.sh`;
override with `ENV_FILE=/etc/pi-sd-backup.env`). A UUID always wins over the
matching `*_DEV` name. If source and destination resolve to the same disk, the
run aborts.

### Pin by hardware ID instead (`/dev/disk/by-id/`)

`SOURCE_DEV` / `DEST_DEV` also accept a `/dev/disk/by-id/...` symlink — the
script canonicalizes it to the real device (`/dev/sdb`) before every check, so
all the safety guards still apply. List the available ids with `ls -l
/dev/disk/by-id/`.

Choose per your setup:

- **Filesystem UUID** lives on the card, so it follows the card between
  readers — but a blank or freshly reformatted card has no UUID to resolve.
- **`by-id`** identifies the hardware, so it works even on a blank card — but
  for a USB SD reader the id usually belongs to the *reader*, not the card, so
  it changes if you swap readers.

## Scheduling with cron

Run as root's crontab (`sudo crontab -e`), e.g. nightly at 3 AM:

```cron
0 3 * * * /path/to/backup.sh >> /var/log/pi-sd-backup.log 2>&1
```

## Safety checks

The script aborts before writing if any of these fail:

- Not run as root.
- Source or destination is missing / not a block device.
- Destination is smaller than the source.
- Any partition on the destination is currently mounted (guards against
  clobbering a live filesystem).
- A pinned `SOURCE_UUID` / `DEST_UUID` can't be resolved, or both resolve to
  the same disk.

## Caveats

- **Data loss risk.** `dd` overwrites the destination unconditionally. Double-
  check `DEST_DEV` — pointing it at the wrong disk destroys that disk.
- The backup is crash-consistent, not clean (see *How it works*).

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Versions are git tags (`vX.Y.Z`), following SemVer.
