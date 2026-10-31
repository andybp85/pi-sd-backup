# shellcheck shell=bash
# dd_command.sh — sourced by backup.sh; tested by tests/dd_command_test.sh.

# Print the backup command, one argument per line (read it with mapfile -t).
# Args: source device, destination device, block size, write limit.
# An empty write limit gives a plain dd. A limit (bytes/s, systemd suffixes
# such as 8M) runs dd in a transient systemd scope whose cgroup caps writes to
# the destination. On a Pi 3B+, every USB port shares one host controller; an
# uncapped dd to a USB card reader starved a USB audio device on the same bus.
# oflag=direct sends each write straight to the device, so the cap applies as
# dd writes, not later in one page-cache writeback burst.
dd_command() {
    local source="$1" dest="$2" block_size="$3" write_limit="$4"
    if [[ -n "$write_limit" ]]; then
        printf '%s\n' systemd-run --scope --quiet "--property=IOWriteBandwidthMax=$dest $write_limit" \
            dd "if=$source" "of=$dest" "bs=$block_size" conv=noerror,sync oflag=direct status=progress
        return
    fi
    printf '%s\n' dd "if=$source" "of=$dest" "bs=$block_size" conv=noerror,sync status=progress
}
