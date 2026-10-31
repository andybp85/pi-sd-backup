# shellcheck shell=bash
# block_size.sh — sourced by backup.sh; tested by tests/block_size_test.sh.

# Print the largest power-of-two block size (512 B to 4 MiB) that divides the
# device size in bytes. dd's conv=sync pads a short final read to a full block.
# If the block size does not divide the device, that padding goes past the end
# of the destination and dd fails with "No space left on device".
# Return 1 if no such size exists (the size is not a multiple of 512).
block_size_for() {
    local bytes="$1" size=4194304
    while ((size > 512 && bytes % size != 0)); do
        size=$((size / 2))
    done
    ((bytes % size == 0)) || return 1
    echo "$size"
}
