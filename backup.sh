#!/bin/bash
# backup.sh — Live Raspberry Pi SD card backup via dd
# Copies /dev/mmcblk0 (main SD) to /dev/sdb (backup SD) without unmounting.
# Run as root, ideally via cron at a low-activity time (e.g. 3 AM).
#
# Usage: sudo ./backup.sh [--dry-run]

set -euo pipefail

# Load optional config (device UUIDs, overrides) from an env file kept off the
# repo. Defaults to a .env beside the script; override with ENV_FILE=/etc/....
ENV_FILE="${ENV_FILE:-$(dirname "$0")/.env}"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090  # path is chosen at runtime; nothing static to follow
    source "$ENV_FILE"
    set +a
fi

SOURCE="${SOURCE_DEV:-/dev/mmcblk0}"
DEST="${DEST_DEV:-/dev/sdb}"
SOURCE_UUID="${SOURCE_UUID:-}" # optional: pin source by filesystem UUID
DEST_UUID="${DEST_UUID:-}"     # optional: pin destination by filesystem UUID
LOG_FILE="${LOG_FILE:-/var/log/pi-sd-backup.log}"
LOG_LEVEL="${LOG_LEVEL:-ERROR}" # ERROR | INFO
BLOCK_SIZE="4M"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Logging ───────────────────────────────────────

log() {
    local level="$1"
    shift
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

info() { [[ "$LOG_LEVEL" == "INFO" ]] && log "INFO " "$@" || true; }
warn() { [[ "$LOG_LEVEL" == "INFO" ]] && log "WARN " "$@" || true; }
error() { log "ERROR" "$@"; }

die() {
    error "$@"
    exit 1
}

# ── Device resolution ─────────────────────────────

# Resolve a filesystem UUID to its whole-disk device (e.g. abc-123 → /dev/sdb).
# Kernel names like /dev/sdb are not stable across reboots or re-plugs; a UUID
# always points at the same card, so dd never writes to the wrong disk.
resolve_disk() {
    local uuid="$1" part parent
    part=$(blkid -U "$uuid" 2>/dev/null) || return 1
    [[ -n "$part" ]] || return 1
    parent=$(lsblk -no pkname "$part" 2>/dev/null | head -n1)
    if [[ -n "$parent" ]]; then
        echo "/dev/$parent"
    else
        echo "$part" # UUID is on a whole disk, not a partition
    fi
}

# ── Pre-flight checks ─────────────────────────────

[[ $EUID -eq 0 ]] || die "Must be run as root (use: sudo $0)"

# UUID (when provided) wins over device name — it is the stable identifier.
if [[ -n "$SOURCE_UUID" ]]; then
    SOURCE=$(resolve_disk "$SOURCE_UUID") || die "No block device found for SOURCE_UUID=$SOURCE_UUID"
    info "Resolved SOURCE_UUID to $SOURCE"
fi
if [[ -n "$DEST_UUID" ]]; then
    DEST=$(resolve_disk "$DEST_UUID") || die "No block device found for DEST_UUID=$DEST_UUID. Is the backup SD card inserted?"
    info "Resolved DEST_UUID to $DEST"
fi

[[ -b "$SOURCE" ]] || die "Source device $SOURCE not found or is not a block device"
[[ -b "$DEST" ]] || die "Destination device $DEST not found. Is the backup SD card inserted?"

# Canonicalize to kernel names (e.g. /dev/disk/by-id/... → /dev/sdb) so the
# mounted-partition guard (which matches /proc/mounts) and the size checks work
# no matter how the device was specified — plain path, by-id symlink, or UUID.
SOURCE=$(readlink -f "$SOURCE")
DEST=$(readlink -f "$DEST")

if [[ "$SOURCE" == "$DEST" ]]; then
    die "Source and destination resolve to the same disk ($SOURCE). Aborting."
fi

SOURCE_BYTES=$(lsblk -bdn -o SIZE "$SOURCE")
DEST_BYTES=$(lsblk -bdn -o SIZE "$DEST")
SOURCE_GB=$((SOURCE_BYTES / 1024 / 1024 / 1024))
DEST_GB=$((DEST_BYTES / 1024 / 1024 / 1024))

info "Source : $SOURCE (${SOURCE_GB} GB)"
info "Dest   : $DEST   (${DEST_GB} GB)"

if ((DEST_BYTES < SOURCE_BYTES)); then
    die "Destination (${DEST_GB} GB) is smaller than source (${SOURCE_GB} GB). Aborting."
fi

# Abort if destination has mounted partitions (e.g. sdb1, sdb2)
if grep -qsF "$DEST" /proc/mounts; then
    error "One or more partitions on $DEST appear to be mounted:"
    grep -F "$DEST" /proc/mounts | while read -r line; do error "  $line"; done
    error "Unmount them before running backup to avoid data corruption."
    die "Aborting due to mounted destination partitions."
fi

# ── Backup ────────────────────────────────────────

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
    ELAPSED=$((END_TIME - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECS=$((ELAPSED % 60))
    info "Backup completed successfully in ${MINUTES}m ${SECS}s."
else
    die "dd exited with an error. Check $LOG_FILE for details."
fi
