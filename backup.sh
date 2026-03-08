#!/bin/bash
# backup.sh — Live Raspberry Pi SD card backup via dd
# Copies /dev/mmcblk0 (main SD) to /dev/sdb (backup SD) without unmounting.
# Run as root, ideally via cron at a low-activity time (e.g. 3 AM).
#
# Usage: sudo ./backup.sh [--dry-run]

set -euo pipefail

SOURCE="${SOURCE_DEV:-/dev/mmcblk0}"
DEST="${DEST_DEV:-/dev/sdb}"
LOG_FILE="${LOG_FILE:-/var/log/pi-sd-backup.log}"
BLOCK_SIZE="4M"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Logging ────────────────────────────────────────────────────────────────────

log() {
    local level="$1"; shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

info()  { log "INFO " "$@"; }
warn()  { log "WARN " "$@"; }
error() { log "ERROR" "$@"; }

die() {
    error "$@"
    exit 1
}

# ── Pre-flight checks ──────────────────────────────────────────────────────────

[[ $EUID -eq 0 ]] || die "Must be run as root (use: sudo $0)"

[[ -b "$SOURCE" ]] || die "Source device $SOURCE not found or is not a block device"
[[ -b "$DEST"   ]] || die "Destination device $DEST not found. Is the backup SD card inserted?"

SOURCE_BYTES=$(blockdev --getsize64 "$SOURCE")
DEST_BYTES=$(blockdev --getsize64 "$DEST")
SOURCE_GB=$(( SOURCE_BYTES / 1024 / 1024 / 1024 ))
DEST_GB=$(( DEST_BYTES   / 1024 / 1024 / 1024 ))

info "Source : $SOURCE (${SOURCE_GB} GB)"
info "Dest   : $DEST   (${DEST_GB} GB)"

if (( DEST_BYTES < SOURCE_BYTES )); then
    die "Destination (${DEST_GB} GB) is smaller than source (${SOURCE_GB} GB). Aborting."
fi

# Warn if destination has mounted partitions (e.g. sdb1, sdb2)
if grep -qs "${DEST}" /proc/mounts; then
    warn "One or more partitions on $DEST appear to be mounted:"
    grep "${DEST}" /proc/mounts | while read -r line; do warn "  $line"; done
    warn "Unmount them before running backup to avoid data corruption."
    die "Aborting due to mounted destination partitions."
fi

# ── Backup ─────────────────────────────────────────────────────────────────────

info "Flushing filesystem buffers (sync)..."
sync

if $DRY_RUN; then
    info "DRY RUN — would execute:"
    info "  dd if=$SOURCE of=$DEST bs=$BLOCK_SIZE conv=noerror,sync status=progress"
    info "Dry run complete. No data written."
    exit 0
fi

info "Starting backup: $SOURCE → $DEST (block size: $BLOCK_SIZE)"
info "This will take several minutes. Do not remove either card."

START_TIME=$(date +%s)

if dd if="$SOURCE" of="$DEST" bs="$BLOCK_SIZE" conv=noerror,sync status=progress 2>&1 | tee -a "$LOG_FILE"; then
    sync
    END_TIME=$(date +%s)
    ELAPSED=$(( END_TIME - START_TIME ))
    MINUTES=$(( ELAPSED / 60 ))
    SECONDS=$(( ELAPSED % 60 ))
    info "Backup completed successfully in ${MINUTES}m ${SECONDS}s."
else
    die "dd exited with an error. Check $LOG_FILE for details."
fi
