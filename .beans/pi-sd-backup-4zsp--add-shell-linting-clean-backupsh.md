---
# pi-sd-backup-4zsp
title: Add shell linting; clean backup.sh
status: in-progress
type: task
priority: normal
created_at: 2026-10-30T13:23:26Z
updated_at: 2026-10-30T13:23:33Z
---

Install shellcheck + shfmt via repo-tooling, fix all findings and the 4 lines over 140 columns in backup.sh without behavior change, release 1.0.1.

- [x] Run install-shell-tooling.sh; commit config
- [ ] Fix shellcheck/shfmt findings and long lines in backup.sh
- [ ] Bump to 1.0.1 with changelog entry
