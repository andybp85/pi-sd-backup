#!/bin/bash
# Unit tests for block_size_for (lib/block_size.sh). Run: bash tests/block_size_test.sh
set -euo pipefail

# shellcheck source=../lib/block_size.sh
source "$(dirname "$0")/../lib/block_size.sh"

failures=0

expect() {
    local bytes="$1" want="$2" got
    got=$(block_size_for "$bytes")
    if [[ "$got" == "$want" ]]; then
        echo "ok   block_size_for $bytes = $want"
    else
        echo "FAIL block_size_for $bytes: want $want, got $got"
        failures=$((failures + 1))
    fi
}

expect 128177930240 4194304 # pi.home card: exact multiple of 4 MiB
expect 31914983424 524288   # tv-dsp card: 7609.125 x 4 MiB → 512 KiB divides it
expect 512 512              # one sector
expect 1536 512             # 3 sectors: only 512 divides it
expect 8388608 4194304      # 8 MiB: capped at 4 MiB

if block_size_for 1000 >/dev/null; then
    echo "FAIL block_size_for 1000: want error (not a multiple of 512), got success"
    failures=$((failures + 1))
else
    echo "ok   block_size_for 1000 fails"
fi

((failures == 0)) || {
    echo "$failures failure(s)"
    exit 1
}
echo "all passed"
