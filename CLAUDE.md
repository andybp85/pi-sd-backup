# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A bash script (`backup.sh`) that performs nightly live backups of a Raspberry Pi's SD card (`/dev/mmcblk0`)
to a second SD card (`/dev/sdb`) using `dd`, without unmounting the source. The Pi must stay running during
backup because it serves the home network.

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

Prefer pinning cards by filesystem UUID (`SOURCE_UUID` / `DEST_UUID`) over
`/dev/sdb` names, which are not stable. Put real UUIDs in a gitignored `.env`
on the Pi (see `.env.example`); the script sources it automatically. Never
commit real UUIDs.

## Scheduling with cron

Add to root's crontab (`sudo crontab -e`):

```text
0 3 * * * /path/to/backup.sh >> /var/log/pi-sd-backup.log 2>&1
```

## Key design decisions

- **Live copy**: The source is never unmounted. A `sync` is issued first to flush buffers, minimizing (but
  not eliminating) filesystem inconsistency. The backup card may need `fsck` on first boot — the Pi's kernel
  does this automatically.
- **`conv=noerror,sync`**: `noerror` prevents dd from aborting on read errors; `sync` pads bad blocks with
  zeroes so partition offsets stay correct.
- **Block size divides the source**: `lib/block_size.sh` picks the largest power-of-two block (≤ 4 MiB) that
  divides the source size. A fixed 4M failed on a 31914983424-byte card: `sync` padded the last partial read
  past the end of the destination (ENOSPC, exit 1). Tests: `bash tests/block_size_test.sh`.
- **Size check**: Script aborts if the destination card is smaller than the source.
- **Mounted destination guard**: Script aborts if any partition on `/dev/sdb` is already mounted, to prevent
  clobbering a live filesystem.
- **Stable device identification**: Optional `SOURCE_UUID` / `DEST_UUID` resolve (via `blkid` +
  `lsblk pkname`) to whole-disk devices at runtime, so unstable kernel names can't misdirect `dd`; UUID wins
  over the `*_DEV` name. `*_DEV` also accepts a `/dev/disk/by-id/...` symlink. All forms are canonicalized
  with `readlink -f` to a kernel name before the guards run, so the mounted-partition check (which matches
  `/proc/mounts`) and size checks stay consistent. The run aborts if source and destination resolve to the
  same disk. Real UUIDs live in a gitignored `.env`, never the repo.
- **Log level**: Controlled via `LOG_LEVEL` env var (`ERROR` by default, `INFO` for verbose). `error`/`die`
  always log; `info`/`warn` are suppressed at the default level.
