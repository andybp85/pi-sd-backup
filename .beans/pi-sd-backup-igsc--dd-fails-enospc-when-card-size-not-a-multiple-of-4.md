---
# pi-sd-backup-igsc
title: dd fails ENOSPC when card size not a multiple of 4M
status: in-progress
type: bug
priority: normal
created_at: 2026-10-31T11:47:43Z
updated_at: 2026-10-31T11:49:05Z
---

On tv-dsp (31914983424 B card = 7609.125 x 4MiB), conv=sync pads the final partial read to 4MiB, so dd writes past the end of the destination and exits 1 (No space left on device). All data is copied; exit status is wrong.

- [x] Regression test for block-size choice
- [x] Pick largest power-of-two bs <= 4MiB dividing source size
- [x] Docs + changelog
- [ ] Deploy and re-run on tv-dsp
