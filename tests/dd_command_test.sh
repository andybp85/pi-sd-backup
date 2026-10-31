#!/bin/bash
# Unit tests for dd_command (lib/dd_command.sh). Run: bash tests/dd_command_test.sh
set -euo pipefail

# shellcheck source=../lib/dd_command.sh
source "$(dirname "$0")/../lib/dd_command.sh"

failures=0

expect() {
    local label="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        echo "ok   $label"
    else
        printf 'FAIL %s\n  want: %s\n  got:  %s\n' "$label" "$want" "$got"
        failures=$((failures + 1))
    fi
}

# The command is printed one argument per line; join for comparison.
joined() { dd_command "$@" | paste -sd ' ' -; }

expect "unthrottled: plain dd" \
    "dd if=/dev/mmcblk0 of=/dev/sda bs=524288 conv=noerror,sync status=progress" \
    "$(joined /dev/mmcblk0 /dev/sda 524288 "")"

expect "throttled: dd in a systemd scope capped on the destination, direct writes" \
    "systemd-run --scope --quiet --property=IOWriteBandwidthMax=/dev/sda 8M dd if=/dev/mmcblk0 of=/dev/sda bs=524288 conv=noerror,sync oflag=direct status=progress" \
    "$(joined /dev/mmcblk0 /dev/sda 524288 8M)"

((failures == 0)) || {
    echo "$failures failure(s)"
    exit 1
}
echo "all passed"
