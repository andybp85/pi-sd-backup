---
# pi-sd-backup-ltt8
title: Throttle dd writes (DEST_WRITE_LIMIT)
status: in-progress
type: feature
priority: normal
created_at: 2026-10-31T13:39:23Z
updated_at: 2026-10-31T13:42:55Z
---

On tv-dsp, unthrottled dd to the USB card reader starved the UR23 SPDIF receiver on the shared Pi 3B+ USB bus; it wedged and needed a USB port reset. Optional DEST_WRITE_LIMIT runs dd under systemd-run IOWriteBandwidthMax with oflag=direct.

- [x] Test for dd command construction
- [x] Implement lib/dd_command.sh + wire into backup.sh
- [x] Docs (README table, .env.example, CLAUDE.md, CHANGELOG)
- [x] Verify throttle (pi.home kernel lacks BLK_DEV_THROTTLING -> preflight added; verified 4.0 MB/s on tv-dsp)
- [x] Deploy; set DEST_WRITE_LIMIT on tv-dsp (8M, 98d1815)
- [ ] Confirm UR23 audio survives a throttled run with the TV on (8M is unproven)
