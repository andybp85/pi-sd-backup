# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). The version lives in the git tag (`vX.Y.Z`).

<!-- Public API: the --dry-run flag, the environment variables in the README table, the .env file
     contract, and the exit status. A change that breaks any of these is a major bump. -->

## [Unreleased]

### Added

- `DEST_WRITE_LIMIT` caps the write rate to the destination (bytes/s, for example `8M`). Use it when other
  USB devices share the bus. The script aborts if the kernel cannot apply the limit.

### Fixed

- `dd` no longer exits with an error ("No space left on device") when the source card size is not a multiple
  of 4 MiB. The block size is now the largest power of two, up to 4 MiB, that divides the source size, so
  `conv=sync` padding never writes past the end of the destination.

## [1.0.1] - 2026-10-30

### Changed

- `backup.sh` is clean under shellcheck and formatted with shfmt; section rulers fit 140 columns.
  No change to flags, environment variables, output, or exit status.

## [1.0.0] - 2026-10-30

First versioned release. The script runs nightly in production on the Pi; this release declares its
interface stable.

### Added

- Live `dd` backup of the source SD card to a second card, with `sync` first and `conv=noerror,sync`.
- `--dry-run` flag: run every check and report the copy without writing data.
- Guards: abort if the destination is smaller than the source, has a mounted partition, or resolves to
  the same disk as the source.
- `SOURCE_UUID` / `DEST_UUID` to pin cards by filesystem UUID; UUID wins over the device name.
- `SOURCE_DEV` / `DEST_DEV` accept a kernel name or a `/dev/disk/by-id/...` path, canonicalized with
  `readlink -f`.
- `.env` beside the script (or `ENV_FILE`) is sourced automatically; `.env.example` documents it.
- `LOG_FILE` and `LOG_LEVEL` (`ERROR` by default, `INFO` for verbose).

### Fixed

- Size check no longer hangs (uses `lsblk` instead of `wc -c`) and works under cron's minimal `PATH`.

[Unreleased]: https://github.com/andybp85/pi-sd-backup/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/andybp85/pi-sd-backup/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/andybp85/pi-sd-backup/releases/tag/v1.0.0
