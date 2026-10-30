---
# pi-sd-backup-4zsp
title: Add shell linting; clean backup.sh
status: completed
type: task
priority: normal
created_at: 2026-10-30T13:23:26Z
updated_at: 2026-10-30T13:25:28Z
---

Install shellcheck + shfmt via repo-tooling, fix all findings and the 4 lines over 140 columns in backup.sh without behavior change, release 1.0.1.

- [x] Run install-shell-tooling.sh; commit config
- [x] Fix shellcheck/shfmt findings and long lines in backup.sh
- [x] Bump to 1.0.1 with changelog entry

## Summary of Changes

- Ran install-shell-tooling.sh: .shellcheckrc plus a [*.{sh,bash}] section in .editorconfig (343d819).
- backup.sh: shfmt layout, SC2155 split in log(), reason on the SC1090 suppression, section rulers
  trimmed under 140 bytes; README Development section (75ac8df).
- Released 1.0.1 (patch: no interface change).
- Found: .shellcheckrc is missing from the docs guard CODE_SKIP_RE in ~/.claude, so the config-only
  commit needed DOC_GUARD_MODE=warn.
