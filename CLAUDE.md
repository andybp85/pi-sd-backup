# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A bash script (`backup.sh`) that performs nightly live backups of a Raspberry Pi's SD card (`/dev/mmcblk0`) to a second SD card (`/dev/sdb`) using `dd`, without unmounting the source. The Pi must stay running during backup because it serves the home network.

## Running the script

```bash
# Dry run (no data written)
sudo bash backup.sh --dry-run

# Real backup
sudo bash backup.sh
```

Override devices, log path, or log level via environment variables:
```bash
sudo SOURCE_DEV=/dev/mmcblk0 DEST_DEV=/dev/sdb LOG_FILE=/var/log/pi-sd-backup.log bash backup.sh

# Verbose output (default is errors only)
sudo LOG_LEVEL=INFO bash backup.sh
```

## Scheduling with cron

Add to root's crontab (`sudo crontab -e`):
```
0 3 * * * /path/to/backup.sh >> /var/log/pi-sd-backup.log 2>&1
```

## Key design decisions

- **Live copy**: The source is never unmounted. A `sync` is issued first to flush buffers, minimizing (but not eliminating) filesystem inconsistency. The backup card may need `fsck` on first boot — the Pi's kernel does this automatically.
- **`conv=noerror,sync`**: `noerror` prevents dd from aborting on read errors; `sync` pads bad blocks with zeroes so partition offsets stay correct.
- **Size check**: Script aborts if the destination card is smaller than the source.
- **Mounted destination guard**: Script aborts if any partition on `/dev/sdb` is already mounted, to prevent clobbering a live filesystem.
- **Log level**: Controlled via `LOG_LEVEL` env var (`ERROR` by default, `INFO` for verbose). `error`/`die` always log; `info`/`warn` are suppressed at the default level.
